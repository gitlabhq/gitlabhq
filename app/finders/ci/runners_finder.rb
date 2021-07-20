# frozen_string_literal: true

module Ci
  class RunnersFinder < UnionFinder
    include Gitlab::Allowable

    ALLOWED_SORTS = %w[contacted_asc contacted_desc created_at_asc created_at_desc created_date].freeze
    DEFAULT_SORT = 'created_at_desc'

    def initialize(current_user:, group: nil, params:)
      @params = params
      @group = group
      @current_user = current_user
    end

    def execute
      search!
      filter_by_status!
      filter_by_runner_type!
      filter_by_tag_list!
      sort!
      request_tag_list!

      @runners

    rescue Gitlab::Access::AccessDeniedError
      Ci::Runner.none
    end

    def sort_key
      ALLOWED_SORTS.include?(@params[:sort]) ? @params[:sort] : DEFAULT_SORT
    end

    private

    def search!
      @group ? group_runners : all_runners

      @runners = @runners.search(@params[:search]) if @params[:search].present?
    end

    def all_runners
      raise Gitlab::Access::AccessDeniedError unless @current_user&.admin?

      @runners = Ci::Runner.all
    end

    def group_runners
      raise Gitlab::Access::AccessDeniedError unless can?(@current_user, :admin_group, @group)

      # Getting all runners from the group itself and all its descendants
      descendant_projects = Project.for_group_and_its_subgroups(@group)

      @runners = Ci::Runner.belonging_to_group_or_project(@group.self_and_descendants, descendant_projects)
    end

    def filter_by_status!
      filter_by!(:status_status, Ci::Runner::AVAILABLE_STATUSES)
    end

    def filter_by_runner_type!
      filter_by!(:type_type, Ci::Runner::AVAILABLE_TYPES)
    end

    def filter_by_tag_list!
      tag_list = @params[:tag_name].presence

      if tag_list
        @runners = @runners.tagged_with(tag_list)
      end
    end

    def sort!
      @runners = @runners.order_by(sort_key)
    end

    def request_tag_list!
      @runners = @runners.with_tags if !@params[:preload].present? || @params.dig(:preload, :tag_name)
    end

    def filter_by!(scope_name, available_scopes)
      scope = @params[scope_name]

      if scope.present? && available_scopes.include?(scope)
        @runners = @runners.public_send(scope) # rubocop:disable GitlabSecurity/PublicSend
      end
    end
  end
end
