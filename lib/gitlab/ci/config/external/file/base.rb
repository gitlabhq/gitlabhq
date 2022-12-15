# frozen_string_literal: true

module Gitlab
  module Ci
    class Config
      module External
        module File
          class Base
            include Gitlab::Utils::StrongMemoize

            attr_reader :location, :params, :context, :errors

            YAML_WHITELIST_EXTENSION = /.+\.(yml|yaml)$/i.freeze

            def initialize(params, context)
              @params = params
              @context = context
              @errors = []
            end

            def matching?
              location.present?
            end

            def invalid_location_type?
              !location.is_a?(String)
            end

            def invalid_extension?
              location.nil? || !::File.basename(location).match?(YAML_WHITELIST_EXTENSION)
            end

            def valid?
              errors.none?
            end

            def error_message
              errors.first
            end

            def content
              raise NotImplementedError, 'subclass must implement fetching raw content'
            end

            def to_hash
              expanded_content_hash
            end

            def validate!
              context.check_execution_time! if ::Feature.disabled?(:ci_refactoring_external_mapper, context.project)
              validate_location!
              validate_context! if valid?
              fetch_and_validate_content! if valid?
              load_and_validate_expanded_hash! if valid?
            end

            def metadata
              {
                context_project: context.project&.full_path,
                context_sha: context.sha
              }
            end

            def eql?(other)
              other.hash == hash
            end

            def hash
              [params, context.project&.full_path, context.sha].hash
            end

            protected

            def expanded_content_hash
              return unless content_hash

              strong_memoize(:expanded_content_yaml) do
                expand_includes(content_hash)
              end
            end

            def content_hash
              strong_memoize(:content_yaml) do
                ::Gitlab::Ci::Config::Yaml.load!(content)
              end
            rescue Gitlab::Config::Loader::FormatError
              nil
            end

            def validate_location!
              if invalid_location_type?
                errors.push("Included file `#{masked_location}` needs to be a string")
              elsif invalid_extension?
                errors.push("Included file `#{masked_location}` does not have YAML extension!")
              end
            end

            def validate_context!
              raise NotImplementedError, 'subclass must implement validate_context'
            end

            def fetch_and_validate_content!
              context.logger.instrument(:config_file_fetch_content) do
                content # calling the method fetches then memoizes the result
              end

              return if errors.any?

              context.logger.instrument(:config_file_validate_content) do
                validate_content!
              end
            end

            def load_and_validate_expanded_hash!
              context.logger.instrument(:config_file_fetch_content_hash) do
                content_hash # calling the method loads then memoizes the result
              end

              context.logger.instrument(:config_file_expand_content_includes) do
                expanded_content_hash # calling the method expands then memoizes the result
              end

              validate_hash!
            end

            def validate_content!
              if content.blank?
                errors.push("Included file `#{masked_location}` is empty or does not exist!")
              end
            end

            def validate_hash!
              if to_hash.blank?
                errors.push("Included file `#{masked_location}` does not have valid YAML syntax!")
              end
            end

            def expand_includes(hash)
              External::Processor.new(hash, context.mutate(expand_context_attrs)).perform
            end

            def expand_context_attrs
              {}
            end

            def masked_location
              strong_memoize(:masked_location) do
                context.mask_variables_from(location)
              end
            end
          end
        end
      end
    end
  end
end
