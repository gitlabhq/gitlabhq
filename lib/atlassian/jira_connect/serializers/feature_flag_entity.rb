# frozen_string_literal: true

module Atlassian
  module JiraConnect
    module Serializers
      class FeatureFlagEntity < Grape::Entity
        include Gitlab::Routing

        alias_method :flag, :object

        format_with(:string, &:to_s)

        expose :schema_version, as: :schemaVersion
        expose :id, format_with: :string
        expose :name, as: :key
        expose :update_sequence_id, as: :updateSequenceId
        expose :name, as: :displayName
        expose :summary
        expose :details
        expose :issue_keys, as: :issueKeys

        def issue_keys
          @issue_keys ||= JiraIssueKeyExtractor.new(flag.description).issue_keys
        end

        def schema_version
          '1.0'
        end

        def update_sequence_id
          options[:update_sequence_id] || Client.generate_update_sequence_id
        end

        STRATEGY_NAMES = {
          ::Operations::FeatureFlags::Strategy::STRATEGY_DEFAULT => 'All users',
          ::Operations::FeatureFlags::Strategy::STRATEGY_GITLABUSERLIST => 'User List',
          ::Operations::FeatureFlags::Strategy::STRATEGY_GRADUALROLLOUTUSERID => 'Percent of users',
          ::Operations::FeatureFlags::Strategy::STRATEGY_FLEXIBLEROLLOUT => 'Percent rollout',
          ::Operations::FeatureFlags::Strategy::STRATEGY_USERWITHID => 'User IDs'
        }.freeze

        private

        # The summary does not map very well to our FeatureFlag model.
        #
        # We allow feature flags to have multiple strategies, depending
        # on the environment. Jira expects a single rollout strategy.
        #
        # Also, we don't actually support showing a single flag, so we use the
        # edit path as an interim solution.
        def summary(strategies = flag.strategies)
          {
            url: edit_project_feature_flag_url(flag.project, flag),
            lastUpdated: flag.updated_at.iso8601,
            status: {
              enabled: flag.active,
              defaultValue: '',
              rollout: {
                percentage: strategies.map do |s|
                  s.parameters['rollout'] || s.parameters['percentage']
                end.compact.first&.to_f,
                text: strategies.map { |s| STRATEGY_NAMES[s.name] }.compact.join(', ')
              }.compact
            }
          }
        end

        def details
          envs = flag.strategies.flat_map do |s|
            s.scopes.map do |es|
              env_type = es.environment_scope.scan(/development|testing|staging|production/).first
              [es.environment_scope, env_type, s]
            end
          end

          envs.map do |env_name, env_type, strat|
            summary([strat]).merge(environment: { name: env_name, type: env_type }.compact)
          end
        end
      end
    end
  end
end
