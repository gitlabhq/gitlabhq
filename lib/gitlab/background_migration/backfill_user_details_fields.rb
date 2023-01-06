# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    # Class that will backfill the following fields from user to user_details
    # * linkedin
    # * twitter
    # * skype
    # * website_url
    # * location
    # * organization
    class BackfillUserDetailsFields < BatchedMigrationJob
      operation_name :backfill_user_details_fields
      feature_category :database

      def perform
        query = <<~SQL
          (COALESCE(linkedin, '') IS DISTINCT FROM '')
          OR (COALESCE(twitter, '') IS DISTINCT FROM '')
          OR (COALESCE(skype, '') IS DISTINCT FROM '')
          OR (COALESCE(website_url, '') IS DISTINCT FROM '')
          OR (COALESCE(location, '') IS DISTINCT FROM '')
          OR (COALESCE(organization, '') IS DISTINCT FROM '')
        SQL
        field_limit = UserDetail::DEFAULT_FIELD_LENGTH

        each_sub_batch(
          batching_scope: ->(relation) {
                            relation.where(query).select(
                              'id AS user_id',
                              "substring(COALESCE(linkedin, '') from 1 for #{field_limit}) AS linkedin",
                              "substring(COALESCE(twitter, '') from 1 for #{field_limit}) AS twitter",
                              "substring(COALESCE(skype, '') from 1 for #{field_limit}) AS skype",
                              "substring(COALESCE(website_url, '') from 1 for #{field_limit}) AS website_url",
                              "substring(COALESCE(location, '') from 1 for #{field_limit}) AS location",
                              "substring(COALESCE(organization, '') from 1 for #{field_limit}) AS organization"
                            )
                          }
        ) do |sub_batch|
          upsert_user_details_fields(sub_batch)
        end
      end

      def upsert_user_details_fields(relation)
        connection.execute(
          <<~SQL
            INSERT INTO user_details (user_id, linkedin, twitter, skype, website_url, location, organization)
            #{relation.to_sql}
            ON CONFLICT (user_id)
            DO UPDATE SET
            "linkedin" = EXCLUDED."linkedin",
            "twitter" = EXCLUDED."twitter",
            "skype" = EXCLUDED."skype",
            "website_url" = EXCLUDED."website_url",
            "location" = EXCLUDED."location",
            "organization" = EXCLUDED."organization"
          SQL
        )
      end
    end
  end
end
