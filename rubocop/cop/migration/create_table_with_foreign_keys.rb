# frozen_string_literal: true

require_relative '../../migration_helpers'

module RuboCop
  module Cop
    module Migration
      class CreateTableWithForeignKeys < RuboCop::Cop::Base
        include MigrationHelpers

        # List of tables added to ensure backward compatibility with high traffic tables
        HIGH_TRAFFIC_TABLES = [
          :alert_management_alerts,
          :approvals,
          :ci_namespace_mirrors,
          :ci_refs,
          :deployment_merge_requests,
          :diff_note_positions,
          :error_tracking_error_events,
          :gitlab_subscriptions,
          :gpg_signatures,
          :label_links,
          :lfs_objects,
          :lfs_objects_projects,
          :members,
          :merge_request_cleanup_schedules,
          :merge_request_user_mentions,
          :namespace_settings,
          :oauth_access_grants,
          :pm_package_version_licenses,
          :pm_package_versions,
          :project_ci_cd_settings,
          :project_daily_statistics,
          :project_features,
          :project_settings,
          :project_statistics,
          :protected_branches,
          :resource_state_events,
          :routes,
          :user_agent_details,
          :user_details,
          :user_preferences,
          :users,
          :vulnerability_occurrence_identifiers
        ].freeze

        MSG = 'Creating a table with more than one foreign key at once violates our migration style guide. ' \
          'For more details check the ' \
          'https://docs.gitlab.com/ee/development/migration_style_guide.html#creating-a-new-table-when-we-have-two-foreign-keys'

        def_node_matcher :create_table_with_block?, <<~PATTERN
          (block
            (send nil? :create_table ...)
            (args (arg _var))
            _)
        PATTERN

        def_node_search :belongs_to_and_references, <<~PATTERN
          (send _var {:references :belongs_to} $...)
        PATTERN

        def_node_search :foreign_key_options, <<~PATTERN
          (_pair
            {(sym :foreign_key) (str "foreign_key")}
            {(hash _) (true)}
          )
        PATTERN

        def_node_search :to_table, <<~PATTERN
          (_pair
            {(sym :to_table) (str "to_table")} {(sym $...) (str $...)}
          )
        PATTERN

        def_node_matcher :argument_name?, <<~PATTERN
          {(sym $...) (str $...)}
        PATTERN

        def_node_search :standalone_foreign_keys, <<~PATTERN
          (send _var :foreign_key $...)
        PATTERN

        def on_send(node)
          return unless in_migration?(node)
          return unless node.command?(:create_table)
          return unless create_table_with_block?(node.parent)

          add_offense(node) if violates?(node.parent)
        end

        private

        def violates?(node)
          tables = all_target_tables(node).uniq

          tables.length > 1 && !(tables & forbidden_tables).empty?
        end

        def forbidden_tables
          (large_or_over_limit_tables + HIGH_TRAFFIC_TABLES).uniq
        end

        def all_target_tables(node)
          belongs_to_and_references_foreign_key_targets(node) + standalone_foreign_key_targets(node)
        end

        def belongs_to_and_references_foreign_key_targets(node)
          belongs_to_and_references(node).select { |candidate| has_fk_option?(candidate) }
                                         .flat_map { |definition| definition_to_table_names(definition) }
                                         .compact
        end

        def standalone_foreign_key_targets(node)
          standalone_foreign_keys(node).flat_map { |definition| definition_to_table_names(definition) }
                                       .compact
        end

        def has_fk_option?(candidate)
          foreign_key_options(candidate.last).first
        end

        def definition_to_table_names(definition)
          table_name_from_options(definition.last) || arguments_to_table_names(definition)
        end

        def table_name_from_options(options)
          to_table(options).to_a.first&.first
        end

        def arguments_to_table_names(arguments)
          arguments.select { |argument| argument_name?(argument) }
                   .map(&:value)
                   .map(&:to_s)
                   .map(&:pluralize)
                   .map(&:to_sym)
        end
      end
    end
  end
end
