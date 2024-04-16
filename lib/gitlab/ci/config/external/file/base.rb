# frozen_string_literal: true

module Gitlab
  module Ci
    class Config
      module External
        module File
          class Base
            include Gitlab::Utils::StrongMemoize

            attr_reader :location, :params, :context, :errors

            YAML_ALLOWLIST_EXTENSION = /.+\.(yml|yaml)$/i

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
              location.nil? || !::File.basename(location).match?(YAML_ALLOWLIST_EXTENSION)
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

            # This method is overridden to load context into the memoized result
            # or to lazily load context via BatchLoader
            def preload_context
              # no-op
            end

            def preload_content
              # calling the `content` method either loads content into the memoized result
              # or lazily loads it via BatchLoader
              content
            end

            def validate_location!
              if invalid_location_type?
                errors.push("Included file `#{masked_location}` needs to be a string")
              elsif invalid_extension?
                errors.push("Included file `#{masked_location}` does not have YAML extension!")
              end
            end

            def validate_context!
              raise NotImplementedError, 'subclass must implement `validate_context!`'
            end

            def validate_content!
              errors.push("Included file `#{masked_location}` is empty or does not exist!") if content.blank?
            end

            def load_and_validate_expanded_hash!
              return errors.push("`#{masked_location}`: #{content_result.error}") unless content_result.valid?

              if content_result.interpolated? && context.user.present?
                ::Gitlab::UsageDataCounters::HLLRedisCounter
                  .track_event('ci_interpolation_users', values: context.user.id)
              end

              context.logger.instrument(:config_file_expand_content_includes) do
                expanded_content_hash # calling the method expands then memoizes the result
              end

              validate_hash!
            end

            protected

            def content_inputs
              # TODO: remove support for `with` syntax in 16.1, see https://gitlab.com/gitlab-org/gitlab/-/issues/408369
              # In the interim prefer `inputs` over `with` while allow either syntax.
              params.to_h.slice(:inputs, :with).each_value.first
            end

            def content_result
              context.logger.instrument(:config_file_fetch_content_hash) do
                ::Gitlab::Ci::Config::Yaml::Loader.new(
                  content, inputs: content_inputs, variables: context.variables
                ).load
              end
            end
            strong_memoize_attr :content_result

            def expanded_content_hash
              return if content_result.content.blank?

              strong_memoize(:expanded_content_hash) do
                expand_includes(content_result.content)
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
