# frozen_string_literal: true

module RuboCop
  module Cop
    module Database
      # Prevents calling partitioned CI relation methods on Project without partition scoping.
      #
      # Partitioned CI tables require `.in_partition(partition_id)` to avoid expensive
      # cross-partition scans that can cause database lock contention.
      #
      # @example
      #
      #   # bad
      #   project.all_pipelines
      #   project.builds.where(status: :failed)
      #   @project.job_artifacts.recent
      #
      #   # good
      #   project.all_pipelines.in_partition(106)
      #   project.builds.in_partition(106).where(status: :failed)
      #   @project.job_artifacts.in_partition(106).recent
      #
      class AvoidUnpartitionedCiRelations < RuboCop::Cop::Base
        MSG = 'Avoid calling `%{relation}` on a Project without scoping to a partition. ' \
          'Use `.in_partition(<partition_id>)` to prevent full cross-partition scans on CI tables. ' \
          'See: https://docs.gitlab.com/ee/development/cicd/cicd_tables.html'

        PARTITIONED_CI_RELATIONS = %i[
          all_pipelines
          build_report_results
          build_trace_chunks
          builds
          bridges
          ci_pipelines
          commit_statuses
          daily_build_group_report_results
          job_artifacts
          pending_builds
          pipeline_artifacts
          pipeline_metadata
          processables
          source_pipelines
          sourced_pipelines
          stages
          webide_pipelines
        ].freeze

        # @!method ci_relation_call?(node)
        def_node_matcher :ci_relation_call?, <<~PATTERN
          {
            (send $_ ${#{PARTITIONED_CI_RELATIONS.map(&:inspect).join(' ')}} ...)
            (csend $_ ${#{PARTITIONED_CI_RELATIONS.map(&:inspect).join(' ')}} ...)
          }
        PATTERN

        # @!method in_partition_call?(node)
        def_node_matcher :in_partition_call?, <<~PATTERN
          (call _ :in_partition ...)
        PATTERN

        def on_send(node)
          receiver, relation = ci_relation_call?(node)
          return unless receiver && relation
          return unless looks_like_project?(receiver)
          return if has_in_partition_in_chain?(node)

          add_offense(node.loc.selector, message: format(MSG, relation: relation))
        end
        alias_method :on_csend, :on_send

        private

        def looks_like_project?(node)
          return false unless node

          case node.type
          when :send
            project_returning_methods = %i[
              project
              find_project
              target_project
              source_project
              forked_from_project
            ]
            project_returning_methods.include?(node.method_name)
          when :ivar, :lvar
            variable_name = node.children.first.to_s
            clean_name = variable_name.delete_prefix('@')

            clean_name == 'project' || clean_name.end_with?('_project')
          else
            false
          end
        end

        def has_in_partition_in_chain?(node)
          current = node

          while current
            return true if in_partition_call?(current)

            current = current.parent
            break unless current&.type?(:send, :csend)
          end

          false
        end
      end
    end
  end
end
