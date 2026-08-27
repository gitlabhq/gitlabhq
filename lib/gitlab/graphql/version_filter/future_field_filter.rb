# frozen_string_literal: true

module Gitlab
  module Graphql
    module VersionFilter
      # Removes the query nodes tagged with @gl_introduced at the current
      # milestone or later, so validation runs as if the client never
      # requested them. IntroducedTracer restores the original document for
      # execution and FutureFieldFallback resolves the fields the schema
      # doesn't have to null.
      #
      # Stripping has validation side effects: a variable or fragment used
      # only inside a stripped subtree looks unused, and a parent whose
      # selections were all stripped looks empty. #suppress? identifies the
      # resulting errors so IntroducedTracer can drop them.
      class FutureFieldFilter < GraphQL::Language::Visitor
        attr_reader :future_field_names

        def initialize(document)
          @document = document
          @future_field_names = Set.new
          @variable_names = Set.new
          @fragment_names = Set.new
          @emptied_parent_positions = Set.new

          super
        end

        IntroducedDirective.locations.each do |location|
          define_method(:"on_#{location.downcase}") do |node, parent|
            if future_node?(node)
              collect(node)
              @emptied_parent_positions << [parent.line, parent.col]

              return super(DELETE_NODE, parent)
            end

            super(node, parent)
          end
        end

        def visit
          result = super

          collect_from_spread_fragments

          result
        end

        def contain_future_fields
          @future_field_names.any?
        end

        def suppress?(error)
          case error
          when GraphQL::StaticValidation::VariablesAreUsedAndDefinedError
            error.code == 'variableNotUsed' && @variable_names.include?(error.variable_name)
          when GraphQL::StaticValidation::FragmentsAreUsedError
            error.nodes.all?(GraphQL::Language::Nodes::FragmentDefinition) &&
              @fragment_names.include?(error.fragment_name)
          when GraphQL::StaticValidation::FieldsHaveAppropriateSelectionsError
            error.nodes.all? { |node| emptied_by_strip?(node) }
          else
            false
          end
        end

        private

        def future_node?(node)
          version = introduced_version(node)

          # The filter runs before type validation, so the argument can be
          # any literal; a non-String must not reach VersionInfo.parse.
          return false unless version.is_a?(String)

          introduced = ::Gitlab::VersionInfo.parse(version)

          return false unless introduced.valid?

          # A backend on the introduction milestone (a `-pre` build or a stale
          # CI branch) may not have the field yet, so the tagged milestone
          # itself is tolerated, not only future ones.
          introduced.without_patch >= Gitlab.version_info.without_patch
        end

        def introduced_version(node)
          directive = node.try(:directives)&.find { |d| d.name == IntroducedDirective.graphql_name }

          return if directive.blank?

          directive.arguments.find { |argument| argument.name == 'version' }&.value
        end

        def collect(node)
          each_selection(node) do |child|
            case child
            when GraphQL::Language::Nodes::Field
              @future_field_names << child.name unless child.name.start_with?('__')
              child.arguments.each { |argument| collect_variables(argument.value) }
            when GraphQL::Language::Nodes::FragmentSpread
              @fragment_names << child.name
            end
          end
        end

        # Fragments reached only through stripped subtrees also look unused
        # to the validator, as do the variables they use. Walk them
        # transitively.
        def collect_from_spread_fragments
          definitions = @document.definitions
            .grep(GraphQL::Language::Nodes::FragmentDefinition)
            .index_by(&:name)
          queue = @fragment_names.to_a

          until queue.empty?
            definition = definitions[queue.shift]

            next if definition.nil?

            each_selection(definition) do |node|
              case node
              when GraphQL::Language::Nodes::Field
                node.arguments.each { |argument| collect_variables(argument.value) }
              when GraphQL::Language::Nodes::FragmentSpread
                queue << node.name if @fragment_names.add?(node.name)
              end
            end
          end
        end

        def each_selection(node, &block)
          yield node

          return unless node.respond_to?(:selections)

          node.selections.each { |child| each_selection(child, &block) }
        end

        def collect_variables(value)
          case value
          when GraphQL::Language::Nodes::VariableIdentifier
            @variable_names << value.name
          when GraphQL::Language::Nodes::InputObject
            value.arguments.each { |argument| collect_variables(argument.value) }
          when Array
            value.each { |item| collect_variables(item) }
          end
        end

        # The rewritten document copies the nodes on changed paths, so the
        # emptied parents are matched by source position instead of identity.
        def emptied_by_strip?(node)
          node.respond_to?(:selections) &&
            node.selections.empty? &&
            @emptied_parent_positions.include?([node.line, node.col])
        end
      end
    end
  end
end
