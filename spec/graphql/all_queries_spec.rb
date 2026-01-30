# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'graphql queries', feature_category: :api do
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
    app/assets/javascripts/work_items/graphql/work_item_types_configuration.query.graphql
  ]

  Gitlab::Graphql::Queries.all.each do |definition| # rubocop:disable Rails/FindEach -- Not an ActiveRecord relation
    relative_path = definition.file.delete_prefix("#{Rails.root}/") # rubocop:disable Rails/FilePath -- Can't be used to append '/'

    describe relative_path do
      it 'is a valid query', :aggregate_failures do
        skip if !Gitlab.ee? && foss_queries_using_ee_fields.include?(relative_path)

        expect(definition).to be_a_valid_graphql_query
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
end
