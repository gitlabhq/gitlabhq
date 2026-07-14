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
        return ServiceResponse.error(message: 'Organization has already been activated') if organization.active?
        return ServiceResponse.success if top_level_group_ids.empty?

        upsert_organization_owners
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
        top_level_group_members.each_batch(of: BATCH_SIZE) do |batch|
          upsert_batch(batch.pluck(:user_id).compact, :default) # rubocop:disable Database/AvoidUsingPluckWithoutLimit -- batch size controlled by each_batch
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
