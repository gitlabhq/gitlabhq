# frozen_string_literal: true

module RuboCop
  module Cop
    module Gitlab
      class BoundedContexts < RuboCop::Cop::Base
        DOC_LINK = "https://docs.gitlab.com/ee/development/software_design#bounded-contexts"
        MODULE_MSG = "Module `%{identifier}` is not a valid bounded context. See #{DOC_LINK}.".freeze
        CLASS_MSG = "Class `%{identifier}` is not within a valid bounded context module. See #{DOC_LINK}.".freeze

        # We ignore the EE namespace because it's a special case used for extending
        # the Enterprise Edition code.
        # We ignore GraphQL top-level namespaces because it's the way organize GraphQL code.
        # These are ignored after the EE module because GraphQL code can be namespaced under EE too.
        IGNORED_TOP_LEVEL_NAMESPACES = %w[EE Mutations Types::PermissionTypes Types PermissionTypes Resolvers].freeze

        class << self
          def external_dependency_checksum
            @external_dependency_checksum ||=
              Digest::SHA256.file(config_file_path).hexdigest
          end

          def bounded_contexts
            @bounded_contexts ||= begin
              data = YAML.load_file(config_file_path)
              Set.new(data.fetch("domains").keys + data.fetch("platform").keys)
            end
          end

          def config_file_path
            File.expand_path("../../../config/bounded_contexts.yml", __dir__ || ".")
          end
        end

        def on_module(node)
          run_check(node, MODULE_MSG)
        end

        def on_class(node)
          run_check(node, CLASS_MSG)
        end

        # Used by RuboCop to invalidate its cache if the contents of `config_file_path` changes.
        def external_dependency_checksum
          self.class.external_dependency_checksum
        end

        private

        def run_check(node, message_template)
          return if @offense_added

          collect_identifiers(node)

          return if identifiers.empty?
          return if self.class.bounded_contexts.include?(identifiers.first)

          @offense_added = true
          add_offense(node.loc.name, message: format(message_template, identifier: identifiers.join('::')))
        end

        def collect_identifiers(node)
          return if identifiers.any?

          full_id = full_identifier_for(node)
          namespace = IGNORED_TOP_LEVEL_NAMESPACES.find { |n| full_id.starts_with?(n) }
          full_id.sub!(/^#{namespace}(::)*/, '') if namespace

          identifiers.concat(full_id.split('::'))
        end

        def identifiers
          @identifiers ||= []
        end

        def full_identifier_for(node)
          node.identifier.source.sub(/^::/, '')
        end
      end
    end
  end
end
