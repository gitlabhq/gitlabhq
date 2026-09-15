# frozen_string_literal: true

module Resolvers
  module Analytics
    module Aggregation
      module EngineResolver
        class BaseEngineResolver < BaseResolver # rubocop:disable Graphql/ResolverType -- type declared in subclasses
          class << self
            attr_accessor :engine
          end

          # Ability checked against every requested group or project.
          # Set while mounting an engine.
          class_attribute :resource_ability

          argument :descendants_scope, ::Types::Analytics::Aggregation::ScopeInputType,
            required: false,
            description: 'Child groups and projects to aggregate data for. Not supported at project level.'

          def resolve(**arguments)
            authorize!(object) if self.class.authorization.any?

            non_metric_filters = engine_class.filters.reject(&:metric?)
            filters = ::Gitlab::Database::Aggregation::Graphql::Adapter
              .arguments_to_filters(non_metric_filters, arguments)
            request = ::Gitlab::Database::Aggregation::Request.new(filters: filters, metrics: [])

            {
              engine: engine_class.new(context: engine_context(arguments)),
              request: request,
              validate_request: method(:validate_request!)
            }
          end

          private

          def engine_class
            self.class.engine
          end

          def validate_request!(engine_request)
            # no-op; can be overloaded while mounting an engine to
            # further limit requests execution
          end

          # Sources are already authorized against `resource_ability`; they are
          # passed along so engines can run part-level authorization checks.
          def engine_context(arguments)
            sources = aggregation_sources(arguments)

            {
              scope: engine_class.prepare_base_aggregation_scope(sources),
              current_user: current_user,
              authorization_resources: sources
            }
          end

          def aggregation_sources(arguments)
            scope = arguments[:descendants_scope] || {}
            group_paths = Array(scope[:group_full_paths])
            project_paths = Array(scope[:project_full_paths])

            case object
            when ::Project
              # Project-level analytics are always scoped to the project itself.
              if group_paths.any? || project_paths.any?
                raise ::Gitlab::Graphql::Errors::ArgumentError,
                  'groupFullPaths and projectFullPaths arguments are not supported at project level'
              end

              project_paths = [object.full_path]
            when ::Group
              # At group level the arguments are optional: the group itself is
              # aggregated when no sources are requested.
              group_paths = [object.full_path] if group_paths.empty? && project_paths.empty?
            end

            if group_paths.empty? && project_paths.empty?
              raise ::Gitlab::Graphql::Errors::ArgumentError,
                'at least one of the groupFullPaths or projectFullPaths arguments is required'
            end

            authorized_sources!(group_paths, project_paths)
          end

          def authorized_sources!(group_paths, project_paths)
            paths = (group_paths + project_paths).uniq(&:downcase)

            sources_by_path = load_sources(group_paths, project_paths)

            accessible, inaccessible = paths.partition do |path|
              source = sources_by_path[path.downcase]
              source && Ability.allowed?(current_user, resource_ability, source)
            end

            # Missing, out-of-scope, and unauthorized sources are reported
            # identically, so the error does not disclose whether an inaccessible
            # source exists.
            if inaccessible.any?
              raise_resource_not_available_error!(
                format(s_("AggregationEngine|The following sources are not accessible: %{source_ids}"),
                  source_ids: inaccessible.join(', '))
              )
            end

            accessible.map { |path| sources_by_path[path.downcase] }
          end

          def load_sources(group_paths, project_paths)
            sources = load_records(::Group, group_paths, ::Preloaders::GroupPolicyPreloader) +
              load_records(::Project, project_paths, ::Preloaders::ProjectPolicyPreloader)

            sources.index_by { |record| record.full_path.downcase }
          end

          def load_records(model_class, paths, preloader_class)
            return [] if paths.empty?

            records = source_scope(model_class).where_full_path_in(paths).to_a
            preloader_class.new(records, current_user).execute

            records
          end

          def source_scope(model_class)
            case object
            when ::Group
              model_class == ::Group ? object.self_and_descendants : object.all_projects
            when ::Project
              # Only the project itself is ever loaded at project level.
              model_class.id_in(object.id)
            else
              model_class.in_organization(object)
            end
          end
        end
      end
    end
  end
end
