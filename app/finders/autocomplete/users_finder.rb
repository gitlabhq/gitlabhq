# frozen_string_literal: true

module Autocomplete
  class UsersFinder
    include Gitlab::Utils::StrongMemoize

    # The number of users to display in the results is hardcoded to 20, and
    # pagination is not supported. This ensures that performance remains
    # consistent and removes the need for implementing keyset pagination to
    # ensure good performance.
    LIMIT = 20
    BATCH_SIZE = 1000

    attr_reader :current_user, :project, :group, :search,
      :author_id, :todo_filter, :todo_state_filter,
      :filter_by_current_user, :states, :push_code

    def initialize(params:, current_user:, project:, group:)
      @current_user = current_user
      @project = project
      @group = group
      @search = params[:search]
      @author_id = params[:author_id]
      @todo_filter = params[:todo_filter]
      @todo_state_filter = params[:todo_state_filter]
      @filter_by_current_user = params[:current_user]
      @states = params[:states] || ['active']
      @push_code = params[:push_code]
    end

    def execute
      items = limited_users

      if search.blank?
        # Include current user if available to filter by "Me"
        items.unshift(current_user) if prepend_current_user?

        if prepend_author? && author&.active?
          items.unshift(author)
        end
      end

      items = filter_users_by_push_ability(items)

      items.uniq.tap do |unique_items|
        preload_associations(unique_items)
      end
    end

    private

    def author
      strong_memoize(:author) do
        User.find_by_id(author_id)
      end
    end

    # Returns the users based on the input parameters, as an Array.
    #
    # This method is separate so it is easier to extend in EE.
    # rubocop: disable CodeReuse/ActiveRecord
    def limited_users
      # When changing the order of these method calls, make sure that
      # reorder_by_name() is called _before_ optionally_search(), otherwise
      # reorder_by_name will break the ORDER BY applied in optionally_search().
      if project
        project.authorized_users.union_with_user(author_id).merge(users_relation)
      elsif group
        find_group_users(group)
      elsif current_user
        users_relation
      else
        User.none
      end.to_a
    end

    def users_relation
      User
        .where(state: states)
        .non_internal
        .reorder_by_name
        .optionally_search(search, use_minimum_char_limit: use_minimum_char_limit)
        .limit_to_todo_authors(
          user: current_user,
          with_todos: todo_filter,
          todo_state: todo_state_filter
        )
        .limit(LIMIT)
    end
    # rubocop: enable CodeReuse/ActiveRecord

    def prepend_current_user?
      filter_by_current_user.present? && current_user
    end

    def prepend_author?
      author_id.present? && current_user
    end

    def find_group_users(group)
      if Feature.enabled?(:group_users_autocomplete_using_batch_reduction, current_user)
        members_relation = ::Autocomplete::GroupUsersFinder.new(group: group, members_relation: true).execute # rubocop: disable CodeReuse/Finder

        user_ids = Set.new
        members_relation.each_batch(of: BATCH_SIZE) do |relation|
          user_ids += relation.pluck_user_ids
        end

        user_relations = []
        user_ids.to_a.in_groups_of(BATCH_SIZE, false) do |batch_user_ids|
          user_relations << users_relation.id_in(batch_user_ids)
        end

        # When there is more than 1 batch, we need to apply users_relation again on
        # the top results per-batch so that we return results in the correct order.
        if user_relations.empty?
          User.none
        elsif user_relations.one?
          user_relations.first
        else
          # We pluck the ids per batch so that we don't send an unbounded number of ids in one query
          user_ids = user_relations.flat_map(&:pluck_primary_key)
          users_relation.id_in(user_ids)
        end
      else
        ::Autocomplete::GroupUsersFinder.new(group: group).execute.merge(users_relation) # rubocop: disable CodeReuse/Finder
      end
    end

    def filter_users_by_push_ability(items)
      return items unless project && push_code.present?

      items.select { |user| user.can?(:push_code, project) }
    end

    # rubocop: disable CodeReuse/ActiveRecord
    def preload_associations(items)
      ActiveRecord::Associations::Preloader.new(records: items, associations: :status).call
    end
    # rubocop: enable CodeReuse/ActiveRecord

    def use_minimum_char_limit
      return if project.blank? && group.blank?  # We return nil so that we use the default defined in the User model

      false
    end
  end
end
