# frozen_string_literal: true
# rubocop:disable Style/Documentation

module Gitlab
  module BackgroundMigration
    class UpdateUsersWhereTwoFactorAuthRequiredFromGroup # rubocop:disable Metrics/ClassLength
      def perform(start_id, stop_id)
        ActiveRecord::Base.connection.execute <<~SQL
          UPDATE
            users
          SET
            require_two_factor_authentication_from_group = TRUE
          WHERE
            users.id BETWEEN #{start_id}
            AND #{stop_id}
            AND users.require_two_factor_authentication_from_group = FALSE
            AND users.id IN (
              SELECT
                DISTINCT users_groups_query.user_id
              FROM
                (
                  SELECT
                    users.id AS user_id,
                    members.source_id AS group_ids
                  FROM
                    users
                    LEFT JOIN members ON members.source_type = 'Namespace'
                    AND members.requested_at IS NULL
                    AND members.user_id = users.id
                    AND members.type = 'GroupMember'
                  WHERE
                    users.require_two_factor_authentication_from_group = FALSE
                    AND users.id BETWEEN #{start_id}
                    AND #{stop_id}) AS users_groups_query
                    INNER JOIN LATERAL (
                      WITH RECURSIVE "base_and_ancestors" AS (
                        (
                          SELECT
                            "namespaces"."type",
                            "namespaces"."id",
                            "namespaces"."parent_id",
                            "namespaces"."require_two_factor_authentication"
                          FROM
                            "namespaces"
                          WHERE
                            "namespaces"."type" = 'Group'
                            AND "namespaces"."id" = users_groups_query.group_ids
                        )
                        UNION
                          (
                            SELECT
                              "namespaces"."type",
                              "namespaces"."id",
                              "namespaces"."parent_id",
                              "namespaces"."require_two_factor_authentication"
                            FROM
                              "namespaces",
                              "base_and_ancestors"
                            WHERE
                              "namespaces"."type" = 'Group'
                              AND "namespaces"."id" = "base_and_ancestors"."parent_id"
                          )
                      ),
                      "base_and_descendants" AS (
                        (
                          SELECT
                            "namespaces"."type",
                            "namespaces"."id",
                            "namespaces"."parent_id",
                            "namespaces"."require_two_factor_authentication"
                          FROM
                            "namespaces"
                          WHERE
                            "namespaces"."type" = 'Group'
                            AND "namespaces"."id" = users_groups_query.group_ids
                        )
                        UNION
                          (
                            SELECT
                              "namespaces"."type",
                              "namespaces"."id",
                              "namespaces"."parent_id",
                              "namespaces"."require_two_factor_authentication"
                            FROM
                              "namespaces",
                              "base_and_descendants"
                            WHERE
                              "namespaces"."type" = 'Group'
                              AND "namespaces"."parent_id" = "base_and_descendants"."id"
                          )
                      )
                      SELECT
                        "namespaces".*
                      FROM
                        (
                          (
                            SELECT
                              "namespaces"."type",
                              "namespaces"."id",
                              "namespaces"."parent_id",
                              "namespaces"."require_two_factor_authentication"
                            FROM
                              "base_and_ancestors" AS "namespaces"
                            WHERE
                              "namespaces"."type" = 'Group'
                          )
                          UNION
                            (
                              SELECT
                                "namespaces"."type",
                                "namespaces"."id",
                                "namespaces"."parent_id",
                                "namespaces"."require_two_factor_authentication"
                              FROM
                                "base_and_descendants" AS "namespaces"
                              WHERE
                                "namespaces"."type" = 'Group'
                            )
                        ) namespaces
                      WHERE
                        "namespaces"."type" = 'Group'
                        AND "namespaces"."require_two_factor_authentication" = TRUE
                    ) AS hierarchy_tree ON TRUE
                );
        SQL
      end
    end
  end
end
