# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class BackfillOrganizationIdOnOauthApplications < BatchedMigrationJob
      operation_name :backfill_organization_id_on_oauth_applications
      feature_category :system_access

      def perform
        each_sub_batch do |sub_batch|
          owned_by_user_relation = build_user_owned_applications_relation(sub_batch)
          update_organization_ids(owned_by_user_relation)

          owned_by_group_relation = build_group_owned_applications_relation(sub_batch)
          update_organization_ids(owned_by_group_relation)

          owned_by_instance_relation = sub_batch
           .where(owner_type: nil)
           .where(owner_id: nil)
           .where(organization_id: nil)

          lowest_org_id = ::Organizations::Organization.first&.id # rubocop:disable Gitlab/PreventOrganizationFirst -- use the default org, which is the org with the lowest ID on the instance

          owned_by_instance_relation.update_all(organization_id: lowest_org_id) if lowest_org_id
        end
      end

      private

      def build_user_owned_applications_relation(base_relation)
        base_relation
          .where(owner_type: 'User')
          .joins(<<~SQL)
            INNER JOIN users ON users.id = oauth_applications.owner_id AND oauth_applications.owner_type = 'User'
          SQL
          .select("oauth_applications.id as oauth_application_id, users.organization_id as organization_id")
      end

      def build_group_owned_applications_relation(base_relation)
        base_relation
          .where(owner_type: 'Namespace')
          .joins(<<~SQL)
            INNER JOIN namespaces ON namespaces.id = oauth_applications.owner_id AND namespaces.type = 'Group'
          SQL
          .select("oauth_applications.id as oauth_application_id, namespaces.organization_id as organization_id")
      end

      def update_organization_ids(relation)
        # Load the relation once to avoid executing multiple queries.
        # Without .to_a, calling .empty? would execute a COUNT query,
        # then iterating with .map would execute a separate SELECT query.
        records = relation.to_a
        return if records.empty?

        values_clause = records.map do |record|
          "(#{Integer(record.oauth_application_id)}, #{Integer(record.organization_id)})"
        end.join(', ')

        connection.execute(<<~SQL)
          UPDATE oauth_applications
          SET organization_id = values.organization_id
          FROM (VALUES #{values_clause}) AS values(id, organization_id)
          WHERE oauth_applications.id = values.id AND oauth_applications.organization_id IS NULL
        SQL
      end
    end
  end
end
