# frozen_string_literal: true

require_relative '../../migration_helpers'

module RuboCop
  module Cop
    module Migration
      # Cop that checks if columns are added in a way that doesn't require
      # downtime.
      class AddColumnWithDefault < RuboCop::Cop::Cop
        include MigrationHelpers

        # Tables >= 10 GB on GitLab.com as of 02/2020
        BLACKLISTED_TABLES = %i[
          audit_events
          ci_build_trace_sections
          ci_builds
          ci_builds_metadata
          ci_job_artifacts
          ci_pipeline_variables
          ci_pipelines
          ci_stages
          deployments
          events
          issues
          merge_request_diff_commits
          merge_request_diff_files
          merge_request_diffs
          merge_request_metrics
          merge_requests
          note_diff_files
          notes
          project_authorizations
          projects
          push_event_payloads
          resource_label_events
          sent_notifications
          system_note_metadata
          taggings
          todos
          users
          web_hook_logs
        ].freeze

        MSG = '`add_column_with_default` without `allow_null: true` may cause prolonged lock situations and downtime, ' \
          'see https://gitlab.com/gitlab-org/gitlab/issues/38060'.freeze

        def_node_matcher :add_column_with_default?, <<~PATTERN
          (send _ :add_column_with_default $_ ... (hash $...))
        PATTERN

        def on_send(node)
          return unless in_migration?(node)

          add_column_with_default?(node) do |table, options|
            add_offense(node, location: :selector) if offensive?(table, options)
          end
        end

        private

        def offensive?(table, options)
          table_blacklisted?(table) && !nulls_allowed?(options)
        end

        def nulls_allowed?(options)
          options.find { |opt| opt.key.value == :allow_null && opt.value.true_type? }
        end

        def table_blacklisted?(symbol)
          symbol && symbol.type == :sym &&
            BLACKLISTED_TABLES.include?(symbol.children[0])
        end
      end
    end
  end
end
