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

              validate!
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

            def validate!
              validate_execution_time!
              validate_location!
              validate_content! if errors.none?
              validate_hash! if errors.none?
            end

            def validate_execution_time!
              context.check_execution_time!
            end

            def validate_location!
              if invalid_location_type?
                errors.push("Included file `#{location}` needs to be a string")
              elsif invalid_extension?
                errors.push("Included file `#{location}` does not have YAML extension!")
              end
            end

            def validate_content!
              if content.blank?
                errors.push("Included file `#{location}` is empty or does not exist!")
              end
            end

            def validate_hash!
              if to_hash.blank?
                errors.push("Included file `#{location}` does not have valid YAML syntax!")
              end
            end

            def expand_includes(hash)
              External::Processor.new(hash, context.mutate(expand_context_attrs)).perform
            end

            def expand_context_attrs
              {}
            end
          end
        end
      end
    end
  end
end
