# frozen_string_literal: true

module Gitlab
  module Ci
    module Catalog
      module Bundle
        # Flattens a catalog component into one self-contained YAML document,
        # resolving includes, extends, and references while preserving the
        # component's own input markers. Only `local:` and `component:` includes
        # are allowed, and callers must pass an identity authorized to read every
        # include being inlined.
        class Compiler
          CompileError = Class.new(StandardError)

          ALLOWED_INCLUDE_TYPES = %i[local component].freeze

          TIMEOUT_SECONDS = 30

          def initialize(content:, project:, sha:, current_user:)
            @content = content
            @project = project
            @sha = sha
            @current_user = current_user
          end

          def compile
            raise CompileError, 'A compile identity is required' unless current_user

            result = ::Gitlab::Ci::Config::Yaml::Loader.new(content).load_uninterpolated_yaml
            raise CompileError, result.error unless result.valid?

            merged = ::Gitlab::Ci::Config::External::Processor.new(result.content, context).perform
            merged = ::Gitlab::Ci::Config::Extendable.new(merged).to_hash
            merged = ::Gitlab::Ci::Config::Yaml::Tags::Resolver.new(merged).to_hash

            dump_documents(result, merged)
          rescue ::Gitlab::Ci::Config::External::Processor::IncludeError,
            ::Gitlab::Ci::Config::Extendable::ExtensionError,
            ::Gitlab::Ci::Config::Yaml::Tags::TagError,
            ::Gitlab::Ci::Config::External::Context::TimeoutError => e
            raise CompileError, e.message
          end

          private

          attr_reader :content, :project, :sha, :current_user

          def context
            ::Gitlab::Ci::Config::External::Context.new(
              project: project,
              sha: sha,
              user: current_user,
              allowed_include_types: ALLOWED_INCLUDE_TYPES
            ).tap { |ctx| ctx.set_deadline(TIMEOUT_SECONDS) }
          end

          def dump_documents(result, body)
            documents = []
            documents << result.header if result.has_header?
            documents << body

            documents.map { |doc| YAML.dump(doc.deep_stringify_keys) }.join
          end
        end
      end
    end
  end
end
