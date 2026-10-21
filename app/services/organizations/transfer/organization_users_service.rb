# frozen_string_literal: true

module Organizations
  module Transfer
    class OrganizationUsersService
      include BaseServiceUtility
      include Gitlab::Utils::StrongMemoize

      BATCH_SIZE = 1000

      def initialize(organization:)
        @organization = organization
      end

      def execute
        return ServiceResponse.error(message: 'Organization is required') unless organization
        return ServiceResponse.success if top_level_group_ids.empty?

        # Owner derivation ("owns every TLG") is a one-time bootstrap: re-running it on an
        # active organization could wrongly re-grant ownership.
        upsert_organization_owners unless organization.active?
        upsert_all_users_as_default

        ServiceResponse.success
      end

      private

      attr_reader :organization

      # rubocop:disable CodeReuse/ActiveRecord -- complex queries not suitable for model scopes
      def upsert_organization_owners
        # Users who are owners of ALL top-level groups become organization owners.
        # The result set is naturally bounded: it's the intersection of owners across
        # all TLGs, which shrinks as more TLGs are added.
        # rubocop:disable Database/AvoidUsingPluckWithoutLimit -- result bounded by HAVING intersection
        owner_user_ids = top_level_group_members
          .all_owners
          .group(:user_id)
          .having('COUNT(DISTINCT source_id) = ?', top_level_group_ids.size)
          .pluck(:user_id)
        # rubocop:enable Database/AvoidUsingPluckWithoutLimit

        upsert_batch(owner_user_ids, :owner)
      end

      def upsert_all_users_as_default
        backfill_members_for(organization.groups, GroupMember)
        backfill_members_for(organization.projects, ProjectMember)
      end

      def backfill_members_for(sources, member_class)
        sources.each_batch(of: BATCH_SIZE) do |source_batch|
          source_batch.pluck(:id).each do |source_id| # rubocop:disable Database/AvoidUsingPluckWithoutLimit -- bounded by each_batch
            member_class.with_source_id(source_id).non_invite.non_request
              .each_batch(of: BATCH_SIZE) do |member_batch|
                # uniq collapses a user's multiple in-batch memberships; cross-batch dupes fall to :skip.
                user_ids = member_batch.pluck(:user_id).compact.uniq # rubocop:disable Database/AvoidUsingPluckWithoutLimit -- bounded by each_batch
                upsert_batch(user_ids, :default)
              end
          end
        end
      end

      def top_level_group_ids
        organization.groups.top_level.pluck(:id) # rubocop:disable Database/AvoidUsingPluckWithoutLimit -- bounded by org TLG count
      end
      strong_memoize_attr :top_level_group_ids

      def top_level_group_members
        GroupMember.with_source_id(top_level_group_ids).non_invite.non_request
      end
      # rubocop:enable CodeReuse/ActiveRecord

      def upsert_batch(user_ids, access_level)
        records = user_ids.map do |user_id|
          { organization_id: organization.id, user_id: user_id, access_level: access_level }
        end

        on_duplicate = if access_level == :owner
                         Arel.sql('access_level = EXCLUDED.access_level')
                       else
                         :skip
                       end

        Organizations::OrganizationUser.upsert_all(
          records,
          unique_by: [:organization_id, :user_id],
          on_duplicate: on_duplicate
        )
      end
    end
  end
end
