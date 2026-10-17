# frozen_string_literal: true

module Mcp
  module Tools
    module Concerns
      module GovernanceContainerResolver
        extend ActiveSupport::Concern
        include ::Gitlab::ResourceLookup
        include UrlParser

        DEFAULT_CONTAINER_ARGUMENTS = {
          project: :project_id,
          group: :group_id,
          project_or_group: :url
        }.freeze

        CONTAINER_KINDS = %i[project group project_or_group].freeze

        MAX_IDENTIFIERS_PER_ARGUMENT = 100

        URL_VALUE = %r{\Ahttps?://}i

        TooManyContainersError = Class.new(ArgumentError)

        class GovernanceContainerResolutionResult
          attr_reader :containers, :named

          def self.none
            new([], named: 0)
          end

          def initialize(containers, named:)
            @containers = Array(containers).compact
            @named = named
          end

          def none?
            named == 0
          end
        end

        class_methods do
          def ungovernable!
            @ungovernable = true
          end

          def ungovernable?
            @ungovernable == true
          end

          def container_arguments(**kinds)
            @container_arguments = DEFAULT_CONTAINER_ARGUMENTS.merge(kinds).freeze if kinds.any?

            return {} if ungovernable?

            @container_arguments || DEFAULT_CONTAINER_ARGUMENTS
          end
        end

        def ungovernable?
          self.class.ungovernable?
        end

        def container_arguments
          self.class.container_arguments
        end

        def governed_containers(arguments)
          result = GovernanceContainerResolutionResult.new(
            resolve_governance_containers(arguments),
            named: governance_identifiers(arguments).size
          )

          record_resolvers.reduce(result) do |carried, (key, resolver)|
            also_governed_by(carried, arguments[key.to_sym]) { |value| run_record_resolver(resolver, value) }
          end
        end

        def declared_argument_names
          container_arguments.flat_map do |_kind, value|
            value.is_a?(Hash) ? value.keys : Array(value)
          end.map(&:to_s).uniq
        end

        def record_resolvers
          resolvers = container_arguments[:record]
          return {} unless resolvers.is_a?(Hash)

          resolvers
        end

        def run_record_resolver(resolver, value)
          instance_exec(value, &resolver)
        end

        def resolve_governance_containers(arguments)
          container_arguments.slice(*CONTAINER_KINDS).flat_map do |kind, key|
            containers_from_argument(kind, key, arguments)
          end
        end

        def governance_identifiers(arguments)
          container_arguments.slice(*CONTAINER_KINDS).flat_map do |kind, key|
            identifiers_from_argument(kind, key, arguments)
          end
        end

        private

        def also_governed_by(result, identifier)
          return result if identifier.blank?

          containers = Array(yield(identifier)).map { |record| container_from_record(record) }
          return result if containers.any? && containers.all?(::Namespaces::UserNamespace)

          GovernanceContainerResolutionResult.new(
            result.containers + containers.grep_v(::Namespaces::UserNamespace),
            named: result.named + 1
          )
        end

        def also_governed_by_all(result, key, identifiers)
          ids = Array(identifiers).compact.presence
          return result unless ids

          reject_oversized_argument!(key, ids)

          ids = ids.uniq

          GovernanceContainerResolutionResult.new(
            result.containers + Array(yield(ids)),
            named: result.named + ids.size
          )
        end

        def record_id_from(value, expected)
          global_id = ::GlobalID.parse(value)
          return value.presence unless global_id

          global_id.model_id if global_id_matches?(global_id, expected)
        end

        def container_from_record(record)
          return record if record.is_a?(::Project)

          container_from_namespace(record)
        end

        def container_from_namespace(namespace)
          case namespace
          when ::Namespaces::ProjectNamespace then namespace.project
          when ::Group, ::Namespaces::UserNamespace then namespace
          end
        end

        def global_work_item_id?(value)
          ::GlobalID.parse(value)&.model_class == ::WorkItem
        end

        def work_item_containers(ids)
          model_ids = Array(ids).filter_map { |id| record_id_from(id, [::WorkItem, ::Issue]) }

          ::WorkItem.id_in(model_ids).map { |item| item.project || item.namespace }
        end

        def identifiers_from_argument(kind, key, arguments)
          case kind
          when :project then namespace_identifiers(key, arguments, [::Project])
          when :group then namespace_identifiers(key, arguments, [::Group])
          else namespace_identifiers(key, arguments, [::Project, ::Group])
          end
        end

        def containers_from_argument(kind, key, arguments)
          case kind
          when :project then projects_from_argument(key, arguments)
          when :group then groups_from_argument(key, arguments)
          else projects_or_groups_from_argument(key, arguments)
          end
        end

        def namespace_identifiers(key, arguments, expected)
          keys = Array(key).compact
          return [] if keys.empty?

          values = keys.flat_map { |k| Array(arguments[k]) }
          reject_oversized_argument!(keys.first, values)

          values.flat_map do |value|
            value = value.presence&.to_s
            next [] unless value

            url_paths = url_identifiers(value)
            next url_paths if url_paths

            value = UrlParser.unescape_and_scrub_uri(value)
            global_id = ::GlobalID.parse(value)
            next [value] unless global_id
            next [] unless global_id_matches?(global_id, expected)

            [global_id.model_id]
          end.uniq
        end

        def reject_oversized_argument!(key, values)
          return if values.size <= MAX_IDENTIFIERS_PER_ARGUMENT

          raise TooManyContainersError,
            format('%{key} cannot name more than %{max} projects or groups',
              key: key, max: MAX_IDENTIFIERS_PER_ARGUMENT)
        end

        def url_identifiers(value)
          url = URL_VALUE.match?(value)
          paths = reference_pattern_paths(value)
          paths << generic_url_path(value) if url
          return if paths.empty? && !url

          paths.compact.uniq.map { |path| UrlParser.unescape_and_scrub_uri(path) }
        end

        def reference_pattern_paths(url)
          [::MergeRequest, ::Commit].filter_map do |klass|
            match = klass.link_reference_pattern.match(url)
            "#{match[:namespace]}/#{match[:project]}" if match
          end
        end

        def generic_url_path(url)
          parse_parent_url(url)[:path]
        rescue ArgumentError
          nil
        end

        def global_id_matches?(global_id, expected)
          expected.any? { |klass| global_id.model_class <= klass }
        rescue NameError
          false
        end

        def projects_from_argument(key, arguments)
          lookup_projects(identifiers_from_argument(:project, key, arguments))
        end

        def groups_from_argument(key, arguments)
          lookup_groups(identifiers_from_argument(:group, key, arguments))
        end

        def projects_or_groups_from_argument(key, arguments)
          identifiers = identifiers_from_argument(:project_or_group, key, arguments)
          projects = lookup_projects(identifiers)
          claimed = projects.flat_map { |project| [project.id.to_s, project.full_path] }.to_set

          projects + lookup_groups(identifiers.reject { |id| claimed.include?(id) })
        end
      end
    end
  end
end
