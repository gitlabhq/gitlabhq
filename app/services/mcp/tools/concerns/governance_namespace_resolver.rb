# frozen_string_literal: true

module Mcp
  module Tools
    module Concerns
      # Resolves the namespace whose tool rules govern a call.
      #
      # A tool declares which of its arguments carry the project or group it acts on, and
      # resolves them itself: the handler cannot know that `manage_pipeline` spells it
      # `id` while `search_labels` spells it `full_path`. A tool that resolves nothing is
      # served ungoverned, which `governable_tools_namespace_spec` asserts against.
      module GovernanceNamespaceResolver
        extend ActiveSupport::Concern
        include ::Gitlab::ResourceLookup

        DEFAULT_NAMESPACE_ARGUMENTS = { project: :project_id, group: :group_id }.freeze

        # The kinds `resolve_governance_containers` iterates. Anything else a tool
        # declares is dropped here, and reads as "no namespace" rather than as a
        # mistake, so `governable_tools_namespace_spec` fails the build on one.
        CONTAINER_KINDS = %i[project group project_or_group].freeze

        class_methods do
          def ungovernable!
            @ungovernable = true
          end

          def ungovernable?
            @ungovernable == true
          end

          def namespace_arguments
            return {} if ungovernable?

            DEFAULT_NAMESPACE_ARGUMENTS
          end
        end

        def ungovernable?
          self.class.ungovernable?
        end

        def namespace_arguments
          self.class.namespace_arguments
        end

        # Every project or group the call acts on. A tool taking lists can name several,
        # and each one's rules have to be consulted, so this returns all of them rather
        # than the first.
        #
        # Returned as found rather than climbed to their roots: a project-level rule
        # overrides its group's, so the caller needs the project itself, not only the
        # namespace the rules are stored against.
        def resolve_governance_containers(arguments)
          namespace_arguments.slice(*CONTAINER_KINDS).flat_map do |kind, key|
            containers_from_argument(kind, key, arguments)
          end
        end

        private

        def containers_from_argument(kind, key, arguments)
          case kind
          when :project then projects_from_argument(key, arguments)
          when :group then groups_from_argument(key, arguments)
          when :project_or_group then projects_or_groups_from_argument(key, arguments)
          end
        end

        # expected: the container classes the argument may name. A Global ID carries its
        # own class, and project and group IDs share a number space, so a
        # `gid://gitlab/Group/1` left unchecked would be looked up as project 1 and
        # govern the call against a container nobody named.
        def namespace_identifiers(key, arguments, expected)
          return [] if key.blank?

          Array(arguments[key]).filter_map do |value|
            value = value.presence&.to_s
            next unless value

            global_id = ::GlobalID.parse(value)
            # A plain numeric id or full path carries no type to disagree with.
            next value unless global_id
            next unless global_id_matches?(global_id, expected)

            global_id.model_id
          end
        end

        def global_id_matches?(global_id, expected)
          expected.any? { |klass| global_id.model_class <= klass }
        rescue NameError
          # A Global ID naming a class that does not exist matches nothing.
          false
        end

        # Batched, because a list argument is unbounded and this runs before the tool
        # authorizes anything: one identifier per query would let a caller decide how
        # many queries the check costs.
        def projects_from_argument(key, arguments)
          lookup_projects(namespace_identifiers(key, arguments, [::Project]))
        end

        def groups_from_argument(key, arguments)
          lookup_groups(namespace_identifiers(key, arguments, [::Group]))
        end

        # Full paths cannot collide between the two, so whatever the project lookup does
        # not claim is offered to the group lookup.
        def projects_or_groups_from_argument(key, arguments)
          identifiers = namespace_identifiers(key, arguments, [::Project, ::Group])
          projects = lookup_projects(identifiers)
          claimed = projects.flat_map { |project| [project.id.to_s, project.full_path] }.to_set

          projects + lookup_groups(identifiers.reject { |id| claimed.include?(id) })
        end
      end
    end
  end
end
