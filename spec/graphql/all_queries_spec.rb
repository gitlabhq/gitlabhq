# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'graphql queries', feature_category: :api do
  include GraphqlQueryComplexityHelper

  RSpec::Matchers.define :be_a_valid_graphql_query do
    match do |definition|
      @errors = definition.validate(GitlabSchema).second

      @errors.empty?
    end

    failure_message do
      messages = @errors.map(&:message)

      "expected query to be valid but is invalid with errors: #{messages}"
    end
  end

  # rubocop:disable Layout/LineLength -- GraphQL query paths can exceed the line length limit
  foss_queries_using_ee_fields = %w[
    app/assets/javascripts/work_items/graphql/ai_permissions_for_project.query.graphql
    app/assets/javascripts/security_configuration/graphql/set_validity_checks.graphql
    app/assets/javascripts/sidebar/components/labels/labels_select_widget/graphql/epic_update_labels.mutation.graphql
    app/assets/javascripts/sidebar/queries/epic_start_date.query.graphql
    app/assets/javascripts/sidebar/queries/epic_due_date.query.graphql
    app/assets/javascripts/sidebar/queries/update_epic_start_date.mutation.graphql
    app/assets/javascripts/analytics/shared/graphql/dora_metrics.query.graphql
    app/assets/javascripts/ci/runner/graphql/register/provision_google_cloud_runner_project.query.graphql
    app/assets/javascripts/sidebar/queries/epic_confidential.query.graphql
    app/assets/javascripts/sidebar/queries/epic_subscribed.query.graphql
    app/assets/javascripts/work_items/graphql/group_workspace_permissions.query.graphql
    app/assets/javascripts/repository/mutations/lock_path.mutation.graphql
    app/assets/javascripts/ci/runner/graphql/register/provision_google_cloud_runner_group.query.graphql
    app/assets/javascripts/issues/show/queries/promote_to_epic.mutation.graphql
    app/assets/javascripts/search/graphql/blob_search_zoekt.query.graphql
    app/assets/javascripts/sidebar/queries/epic_participants.query.graphql
    app/assets/javascripts/sidebar/queries/update_epic_confidential.mutation.graphql
    app/assets/javascripts/security_configuration/graphql/configure_security_training_providers.mutation.graphql
    app/assets/javascripts/ci/runner/graphql/register/provision_gke_runner_project.query.graphql
    app/assets/javascripts/search/graphql/blob_search_zoekt_count_only.query.graphql
    app/assets/javascripts/ci/runner/graphql/register/provision_gke_runner_group.query.graphql
    app/assets/javascripts/analytics/shared/graphql/flow_metrics.query.graphql
    app/assets/javascripts/sidebar/components/labels/labels_select_widget/graphql/epic_labels.query.graphql
    app/graphql/queries/burndown_chart/burnup.milestone.query.graphql
    app/assets/javascripts/security_configuration/graphql/security_training_vulnerability.query.graphql
    app/assets/javascripts/sidebar/queries/update_epic_subscription.mutation.graphql
    app/assets/javascripts/sidebar/queries/epic_reference.query.graphql
    app/assets/javascripts/security_configuration/graphql/security_tracked_refs.query.graphql
    app/assets/javascripts/security_configuration/graphql/track_security_refs.mutation.graphql
    app/assets/javascripts/security_configuration/graphql/untrack_security_refs.mutation.graphql
    app/assets/javascripts/security_configuration/graphql/security_training_providers.query.graphql
    app/assets/javascripts/sidebar/queries/epic_todo.query.graphql
    app/assets/javascripts/sidebar/queries/update_status.mutation.graphql
    app/assets/javascripts/security_configuration/graphql/set_pre_receive_secret_detection.graphql
    app/assets/javascripts/work_items/graphql/work_items_linked_items_slim.query.graphql
    app/graphql/queries/burndown_chart/burnup.iteration.query.graphql
    app/assets/javascripts/alerts_settings/graphql/queries/parse_sample_payload.query.graphql
    app/assets/javascripts/sidebar/queries/update_epic_due_date.mutation.graphql
    app/assets/javascripts/security_configuration/graphql/set_secret_push_protection.graphql
    app/assets/javascripts/issuable/popover/queries/iteration.query.graphql
    app/assets/javascripts/security_configuration/graphql/set_license_configuration_source.graphql
    app/assets/javascripts/projects/settings/branch_rules/mutations/delete_squash_option.mutation.graphql
    app/assets/javascripts/security_configuration/graphql/security_configuration.query.graphql
    app/assets/javascripts/explore/analytics_dashboards/graphql/get_dashboards.query.graphql
    app/assets/javascripts/explore/analytics_dashboards/graphql/get_dashboard.query.graphql
    app/assets/javascripts/explore/analytics_dashboards/graphql/get_system_dashboard.query.graphql
    app/assets/javascripts/analytics/dashboards/graphql/dora_metrics_by_project.query.graphql
    app/assets/javascripts/analytics/dashboards/graphql/vulnerabilities.query.graphql
    app/assets/javascripts/analytics/dashboards/graphql/contributor_count.query.graphql
    app/assets/javascripts/analytics/dashboards/ai_impact/graphql/ai_agent_platform_flow_metrics.query.graphql
    app/assets/javascripts/analytics/dashboards/ai_impact/graphql/ai_agent_platform_flows_usage_by_user.query.graphql
    app/assets/javascripts/analytics/dashboards/ai_impact/graphql/ai_metrics.query.graphql
    app/assets/javascripts/analytics/dashboards/ai_impact/graphql/code_suggestions_acceptance_by_ide.query.graphql
    app/assets/javascripts/analytics/dashboards/ai_impact/graphql/code_suggestions_acceptance_by_language.query.graphql
    app/assets/javascripts/analytics/dashboards/ai_impact/graphql/code_suggestions_acceptance_rate.query.graphql
    app/assets/javascripts/analytics/dashboards/ai_impact/graphql/code_suggestions_users_count.query.graphql
    app/assets/javascripts/analytics/dashboards/ai_impact/graphql/duo_agent_platform_agent_flows_users_count.query.graphql
    app/assets/javascripts/analytics/dashboards/ai_impact/graphql/duo_agent_platform_chats.query.graphql
    app/assets/javascripts/analytics/dashboards/ai_impact/graphql/duo_feature_usage.query.graphql
    app/assets/javascripts/analytics/dashboards/ai_impact/graphql/duo_power_users_count.query.graphql
    app/assets/javascripts/analytics/dashboards/ai_impact/graphql/duo_used_count.query.graphql
    app/assets/javascripts/analytics/dashboards/ai_impact/graphql/duo_pipelines_rate.query.graphql
    app/assets/javascripts/analytics/dashboards/ai_impact/graphql/finished_pipelines_using_dap.query.graphql
    app/assets/javascripts/pages/projects/shared/permissions/graphql/auto_remediation_profile_attach.mutation.graphql
  ]
  # rubocop:enable Layout/LineLength

  # Selecting one response key with two different types violates the GraphQL
  # specification. GitlabSchema lets these queries run (see
  # GitlabSchema.legacy_invalid_return_type_conflicts), so this guard stops new ones
  # from being added. To fix a query, give each type its own response key with an
  # alias, then remove it from this list.
  # See https://gitlab.com/gitlab-org/gitlab/-/issues/586994
  # rubocop:disable Layout/LineLength -- GraphQL query paths can exceed the line length limit
  queries_with_return_type_conflicts = %w[
    app/assets/javascripts/admin/projects/index/graphql/queries/admin_projects.query.graphql
    app/assets/javascripts/graphql_shared/queries/project_autocomplete_users_with_mr_permissions.query.graphql
    app/assets/javascripts/graphql_shared/queries/workspace_autocomplete_users.query.graphql
    app/assets/javascripts/graphql_shared/subscriptions/work_item_dates.subscription.graphql
    app/assets/javascripts/homepage/graphql/queries/recently_viewed_items.query.graphql
    app/assets/javascripts/packages_and_registries/package_registry/graphql/queries/get_package_details.query.graphql
    app/assets/javascripts/packages_and_registries/package_registry/graphql/queries/get_package_metadata.query.graphql
    app/assets/javascripts/work_items/graphql/create_work_item.mutation.graphql
    app/assets/javascripts/work_items/graphql/namespace_work_item_types.query.graphql
    app/assets/javascripts/work_items/graphql/update_work_item.mutation.graphql
    app/assets/javascripts/work_items/graphql/work_item_by_id.query.graphql
    app/assets/javascripts/work_items/graphql/work_item_by_iid.query.graphql
    app/assets/javascripts/work_items/graphql/work_item_convert.mutation.graphql
    app/assets/javascripts/work_items/graphql/work_item_updated.subscription.graphql
    ee/app/assets/javascripts/ai/catalog/graphql/queries/ai_catalog_custom_and_foundational_items.query.graphql
    ee/app/assets/javascripts/compliance_dashboard/graphql/compliance_requirement_controls.query.graphql
    ee/app/assets/javascripts/diffs/components/graphql/get_mr_codequality_and_security_reports.query.graphql
    ee/app/assets/javascripts/graphql_shared/queries/project_autocomplete_users_with_mr_permissions.query.graphql
    ee/app/assets/javascripts/graphql_shared/subscriptions/issuable_weight.subscription.graphql
    ee/app/assets/javascripts/homepage/graphql/queries/recently_viewed_items.query.graphql
    ee/app/assets/javascripts/rapid_diffs/graphql/get_mr_sast_report.query.graphql
    ee/app/assets/javascripts/security_dashboard/graphql/queries/security_report_finding.query.graphql
    ee/app/assets/javascripts/usage_quotas/pipelines/admin/graphql/queries/dedicated_instance_usage_by_month.query.graphql
    ee/app/assets/javascripts/usage_quotas/pipelines/admin/graphql/queries/dedicated_instance_usage_by_year.query.graphql
    ee/app/assets/javascripts/usage_quotas/usage_billing/users/show/graphql/get_user_subscription_usage_events.query.graphql
    ee/app/assets/javascripts/work_items/graphql/update_work_item_custom_fields.mutation.graphql
  ]
  # rubocop:enable Layout/LineLength

  Gitlab::Graphql::Queries.all.each do |definition| # rubocop:disable Rails/FindEach -- Not an ActiveRecord relation
    relative_path = definition.file.delete_prefix("#{Rails.root}/") # rubocop:disable Rails/FilePath -- Can't be used to append '/'

    describe relative_path do
      it 'is a valid query', :aggregate_failures do
        skip if !Gitlab.ee? && foss_queries_using_ee_fields.include?(relative_path)

        expect(definition).to be_a_valid_graphql_query
      end

      context 'with return type conflicts' do
        before do
          # Turn the conflicts into validation errors so they can be detected here, while
          # production keeps running them.
          allow(GitlabSchema).to receive(:legacy_invalid_return_type_conflicts)
            .and_return(:return_validation_error)
        end

        # This test case fails if:
        # 1. The query has a return type conflict
        # 2. The query's .graphql file is not in queries_with_return_type_conflicts
        it 'gives each response key a single type' do
          skip 'known conflict, tracked in queries_with_return_type_conflicts' if
            queries_with_return_type_conflicts.include?(relative_path)

          conflicts = definition.validate(GitlabSchema).second.select do |error|
            error.is_a?(GraphQL::StaticValidation::FieldsWillMergeError) && error.kind == :return_type
          end

          expect(conflicts.map(&:message)).to be_empty
        end
      end
    end
  end

  describe 'exceptions list' do
    let(:fragments) { Gitlab::Graphql::Queries::Fragments.new(Rails.root) }

    # Remove the file from the exceptions list to pass these tests.
    foss_queries_using_ee_fields.each do |file|
      it 'contains only files that exist' do
        expect(File.exist?(file)).to be(true)
      end

      it 'does not contain files that have been fixed', unless: Gitlab.ee? do
        definition = Gitlab::Graphql::Queries::Definition.new(file, fragments)

        expect(definition).not_to be_a_valid_graphql_query
      end
    end
  end

  # These are CE query files, so this guards their CE-resolved complexity in the FOSS
  # pipeline. The EE-resolved complexity (which is higher because EE adds fields to the
  # shared fragments) is guarded by the equivalent block in ee/spec/graphql/all_queries_spec.rb.
  # `__typename` is injected because Apollo Client adds it at runtime and it counts
  # towards complexity; we assert `<=` since the server only rejects queries that exceed
  # the limit. See https://gitlab.com/gitlab-org/gitlab/-/issues/587970
  describe 'work item detail/mutation query complexity with workItem.features field enabled', unless: Gitlab.ee? do
    %w[
      app/assets/javascripts/work_items/graphql/work_item_by_iid.query.graphql
      app/assets/javascripts/work_items/graphql/work_item_by_id.query.graphql
      app/assets/javascripts/work_items/graphql/create_work_item.mutation.graphql
      app/assets/javascripts/work_items/graphql/update_work_item.mutation.graphql
      app/assets/javascripts/work_items/graphql/work_item_convert.mutation.graphql
      app/assets/javascripts/work_items/graphql/move_work_item.mutation.graphql
      app/assets/javascripts/work_items/graphql/add_linked_items.mutation.graphql
      app/assets/javascripts/work_items/graphql/work_item_updated.subscription.graphql
    ].each do |query_path|
      describe query_path do
        let(:definition) { Gitlab::Graphql::Queries.find(Rails.root.join(query_path)).first }

        it 'does not exceed authenticated max complexity with features enabled' do
          complexity = query_complexity_with_typename(definition.text, { "useWorkItemFeatures" => true })

          expect(complexity).to be <= GitlabSchema::AUTHENTICATED_MAX_COMPLEXITY
        end

        it 'does not exceed admin max complexity with features enabled' do
          complexity = query_complexity_with_typename(definition.text, { "useWorkItemFeatures" => true })

          expect(complexity).to be <= GitlabSchema::ADMIN_MAX_COMPLEXITY
        end
      end
    end
  end

  describe 'return type conflicts exceptions list' do
    let(:fragments) { Gitlab::Graphql::Queries::Fragments.new(Rails.root) }

    before do
      # Turn the conflicts into validation errors so they can be detected here, while
      # production keeps running them.
      allow(GitlabSchema).to receive(:legacy_invalid_return_type_conflicts)
        .and_return(:return_validation_error)
    end

    # Checks that each entry in queries_with_return_type_conflicts has an existing
    # file and still conflicts. Prevents having dead entries in
    # queries_with_return_type_conflicts, and forces fixed queries out of it.
    #
    # EE-only: FOSS has no ee/ directory, so the ee/ entries have no file there, and the
    # conflicts only surface against the EE schema.
    queries_with_return_type_conflicts.each do |file|
      describe "known conflict #{file}", if: Gitlab.ee? do
        it 'references an existing file' do
          # Remove the file from the list to pass this test.
          expect(File.exist?(Rails.root.join(file))).to be(true)
        end

        it 'has not been fixed yet' do
          # Remove the file from the list to pass this test.
          definition = Gitlab::Graphql::Queries::Definition.new(Rails.root.join(file).to_s, fragments)

          conflicts = definition.validate(GitlabSchema).second.select do |error|
            error.is_a?(GraphQL::StaticValidation::FieldsWillMergeError) && error.kind == :return_type
          end

          expect(conflicts).not_to be_empty
        end
      end
    end
  end
end
