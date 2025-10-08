# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Resolvers::Ci::JobAnalyticsResolver, :click_house, feature_category: :fleet_visibility do
  include GraphqlHelpers
  include_context 'with CI job analytics test data', with_pipelines: false

  describe '#resolve' do
    subject(:resolve_scope) do
      resolve(
        described_class,
        obj: project,
        ctx: { current_user: user },
        args: args,
        arg_style: :internal
      )
    end

    let(:query_builder) do
      instance_double(::Ci::JobAnalytics::QueryBuilder,
        execute: ClickHouse::Finders::Ci::FinishedBuildsFinder.new)
    end

    let_it_be_with_reload(:user) { create(:user) }
    let(:args) { {} }

    before do
      stub_application_setting(use_clickhouse_for_analytics: true)
    end

    context 'when user does not have permission to read_ci_cd_analytics' do
      it { is_expected.to be_nil }
    end

    context 'when user has permission to read_ci_cd_analytics' do
      before_all do
        project.add_maintainer(user)
      end

      context 'with default arguments' do
        let(:args) do
          {
            select_fields: [:name],
            aggregations: [:mean_duration_in_seconds, :rate_of_failed, :p95_duration_in_seconds]
          }
        end

        it 'returns ClickHouseAggregatedConnection' do
          expect(resolve_scope).to be_a(::Gitlab::Graphql::Pagination::ClickHouseAggregatedConnection)
        end

        it 'calls QueryBuilderService with correct parameters' do
          expect(::Ci::JobAnalytics::QueryBuilder).to receive(:new).with(project: project,
            current_user: user,
            options: args).and_return(query_builder)

          resolve_scope
        end
      end

      shared_examples 'resolves with filtering' do
        it "correctly configures the QueryBuilder" do
          expect(::Ci::JobAnalytics::QueryBuilder).to receive(:new).with(
            project: project,
            current_user: user,
            options: hash_including(expected_params)
          ).and_return(query_builder)

          is_expected.to be_a(::Gitlab::Graphql::Pagination::ClickHouseAggregatedConnection)
        end
      end

      context 'with name search filter' do
        let(:args) do
          {
            select_fields: [:name],
            aggregations: [:mean_duration_in_seconds],
            name_search: 'compile'
          }
        end

        let(:expected_params) { { name_search: 'compile' } }

        include_examples 'resolves with filtering'
      end

      context 'with source filter' do
        let(:args) do
          {
            select_fields: [:name],
            aggregations: [:rate_of_success],
            source: 'web'
          }
        end

        let(:expected_params) { { source: 'web' } }

        include_examples 'resolves with filtering'
      end

      context 'with ref filter' do
        let(:args) do
          {
            select_fields: [:name],
            aggregations: [:mean_duration_in_seconds],
            ref: 'feature-branch'
          }
        end

        let(:expected_params) { { ref: 'feature-branch' } }

        include_examples 'resolves with filtering'
      end

      context 'with time range filters' do
        let(:from_time) { 24.hours.ago }
        let(:to_time) { Time.current }
        let(:args) do
          {
            select_fields: [:name],
            aggregations: [:mean_duration_in_seconds],
            from_time: from_time,
            to_time: to_time
          }
        end

        let(:expected_params) { { from_time: from_time, to_time: to_time } }

        include_examples 'resolves with filtering'
      end

      context 'with sort parameter' do
        let(:args) do
          {
            select_fields: [:name],
            aggregations: [:mean_duration_in_seconds],
            sort: :mean_duration_in_seconds_desc
          }
        end

        let(:expected_params) { { sort: :mean_duration_in_seconds_desc } }

        include_examples 'resolves with filtering'
      end

      context 'with multiple select fields' do
        let(:args) do
          {
            select_fields: [:name, :stage_id],
            aggregations: [:mean_duration_in_seconds, :rate_of_success, :rate_of_failed]
          }
        end

        let(:expected_params) { args }

        include_examples 'resolves with filtering'
      end

      context 'with all aggregation types' do
        let(:args) do
          {
            select_fields: [:name],
            aggregations: [
              :mean_duration_in_seconds,
              :p95_duration_in_seconds,
              :rate_of_success,
              :rate_of_failed,
              :rate_of_canceled
            ]
          }
        end

        let(:expected_params) { args }

        include_examples 'resolves with filtering'
      end

      context 'with combined filters and sorting' do
        let(:args) do
          {
            select_fields: [:name, :stage_id],
            aggregations: [:mean_duration_in_seconds, :rate_of_failed],
            name_search: 'rspec',
            source: 'push',
            ref: 'main',
            sort: :rate_of_failed_desc,
            from_time: 7.days.ago,
            to_time: Time.current
          }
        end

        let(:expected_params) { args }

        include_examples 'resolves with filtering'
      end

      context 'when QueryBuilder raises ArgumentError' do
        let(:args) do
          {
            select_fields: [:name],
            aggregations: [:mean_duration_in_seconds]
          }
        end

        before do
          allow(::Ci::JobAnalytics::QueryBuilder).to receive(:new)
            .and_raise(ArgumentError, 'Invalid argument')
        end

        it 'raises Gitlab::Graphql::Errors::ArgumentError' do
          expect_graphql_error_to_be_created(
            Gitlab::Graphql::Errors::ArgumentError,
            'Invalid argument'
          ) do
            resolve_scope
          end
        end
      end

      context 'when ClickHouse is not configured' do
        before do
          allow(::Gitlab::ClickHouse).to receive(:configured?).and_return(false)
        end

        let(:args) do
          {
            select_fields: [:name],
            aggregations: [:mean_duration_in_seconds]
          }
        end

        it 'returns resource note available error' do
          expect_graphql_error_to_be_created(Gitlab::Graphql::Errors::ResourceNotAvailable) do
            resolve_scope
          end
        end
      end
    end
  end
end
