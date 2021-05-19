# frozen_string_literal: true

module Projects
  module Members
    class EffectiveAccessLevelFinder
      include Gitlab::Utils::StrongMemoize

      USER_ID_AND_ACCESS_LEVEL = [:user_id, :access_level].freeze
      BATCH_SIZE = 5

      def initialize(project)
        @project = project
      end

      def execute
        return Member.none if no_members?

        # rubocop: disable CodeReuse/ActiveRecord
        Member.from(generate_from_statement(user_ids_and_access_levels_from_all_memberships))
          .select([:user_id, 'MAX(access_level) AS access_level'])
          .group(:user_id)
        # rubocop: enable CodeReuse/ActiveRecord
      end

      private

      attr_reader :project

      def generate_from_statement(user_ids_and_access_levels)
        "(VALUES #{generate_values_expression(user_ids_and_access_levels)}) members (user_id, access_level)"
      end

      def generate_values_expression(user_ids_and_access_levels)
        user_ids_and_access_levels.map do |user_id, access_level|
          "(#{user_id}, #{access_level})"
        end.join(",")
      end

      def no_members?
        user_ids_and_access_levels_from_all_memberships.blank?
      end

      def all_possible_avenues_of_membership
        avenues = [authorizable_project_members]

        avenues << if project.personal?
                     project_owner_acting_as_maintainer
                   else
                     authorizable_group_members
                   end

        if include_membership_from_project_group_shares?
          avenues << members_from_project_group_shares
        end

        avenues
      end

      # @return [Array<[user_id, access_level]>]
      def user_ids_and_access_levels_from_all_memberships
        strong_memoize(:user_ids_and_access_levels_from_all_memberships) do
          all_possible_avenues_of_membership.flat_map do |relation|
            relation.pluck(*USER_ID_AND_ACCESS_LEVEL) # rubocop: disable CodeReuse/ActiveRecord
          end
        end
      end

      def authorizable_project_members
        project.members.authorizable
      end

      def authorizable_group_members
        project.group.authorizable_members_with_parents
      end

      def members_from_project_group_shares
        members = []

        project.project_group_links.each_batch(of: BATCH_SIZE) do |relation|
          members_per_batch = []

          relation.includes(:group).each do |link| # rubocop: disable CodeReuse/ActiveRecord
            members_per_batch << link.group.authorizable_members_with_parents.select(*user_id_and_access_level_for_project_group_shares(link))
          end

          members << Member.from_union(members_per_batch)
        end

        members.flatten
      end

      def project_owner_acting_as_maintainer
        user_id = project.namespace.owner.id
        access_level = Gitlab::Access::MAINTAINER

        Member
          .from(generate_from_statement([[user_id, access_level]])) # rubocop: disable CodeReuse/ActiveRecord
          .limit(1)
      end

      def include_membership_from_project_group_shares?
        project.allowed_to_share_with_group? && project.project_group_links.any?
      end

      # methods for `select` options

      def user_id_and_access_level_for_project_group_shares(link)
        least_access_level_among_group_membership_and_project_share =
          smallest_value_arel([link.group_access, GroupMember.arel_table[:access_level]], 'access_level')

        [
          :user_id,
          least_access_level_among_group_membership_and_project_share
        ]
      end

      def smallest_value_arel(args, column_alias)
        Arel::Nodes::As.new(
          Arel::Nodes::NamedFunction.new('LEAST', args),
          Arel.sql(column_alias)
        )
      end
    end
  end
end
