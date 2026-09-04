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
              @inputs_only = false
            end

            def inputs_only!
              @inputs_only = true
              self
            end

            def inputs_only?
              @inputs_only
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

            def include_type
              raise NotImplementedError, 'subclass must implement `include_type`'
            end

            def metadata
              {
                type: include_type,
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

            def validate_content_presence!
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

              validate_parsed_content_presence!
              validate_content_keys! if inputs_only?
            end

            def validate_content_keys!
              return unless expanded_content_hash

              allowed_keys = %i[inputs]
              unknown_keys = expanded_content_hash.keys - allowed_keys

              return unless unknown_keys.any?

              errors.push("Header include file `#{masked_location}` contains unknown keys: #{unknown_keys}")
            end

            def load_uninterpolated_yaml
              ::Gitlab::Ci::Config::Yaml::Loader.new(content).load_uninterpolated_yaml
            end

            def expanded_context
              context.mutate(expand_context_attrs)
            end
            strong_memoize_attr :expanded_context

            protected

            def content_inputs
              params.to_h.slice(:inputs).each_value.first
            end

            def content_result
              context.logger.instrument(:config_file_fetch_content_hash) do
                ::Gitlab::Ci::Config::Yaml::Loader.new(
                  content, inputs: content_inputs, context: yaml_context, external_context: header_include_context
                ).load
              end
            end
            strong_memoize_attr :content_result

            def header_include_context
              return expanded_context if Feature.enabled?(:ci_spec_include_own_context, flag_actor)

              log_diverging_header_include

              context
            end

            # Context#mutate drops the project under remote and template includes, so the flag
            # would otherwise flip mid-tree.
            def flag_actor
              context.pipeline&.project
            end

            # TODO: remove with the flag, see https://gitlab.com/gitlab-org/gitlab/-/issues/624232
            # Measures the blast radius of the flag: logs the files that resolve a `spec:include` location
            # against the caller today and would resolve it against themselves once the flag is on.
            def log_diverging_header_include
              return unless header_include_diverges?

              Gitlab::AppJsonLogger.info(
                Labkit::Fields::CLASS_NAME => self.class.name,
                Labkit::Fields::GL_PROJECT_ID => context.project&.id,
                message: 'CI config spec:include location resolves outside the declaring file',
                event: 'ci_spec_include_diverging_context',
                Labkit::Fields::ADDITIONAL_DETAILS => {
                  location: masked_location,
                  include_type: include_type,
                  declaring_project_id: expanded_context.project&.id
                }
              )
            end

            def header_include_diverges?
              # Cheapest checks first: a file with no `spec:` at all cannot declare a header, and building
              # the expanded context allocates.
              return false unless content.to_s.include?('spec:')
              return false if expanded_context.project == context.project && expanded_context.sha == context.sha

              header_yaml = load_uninterpolated_yaml
              return false unless header_yaml.valid?

              Array.wrap(header_yaml.spec[:include]).any? do |location|
                (location.is_a?(String) && !::Gitlab::UrlSanitizer.valid?(location)) ||
                  (location.is_a?(Hash) && location.key?(:local))
              end
            end

            def yaml_context
              ::Gitlab::Ci::Config::Yaml::Context.new(**yaml_context_attributes)
            end

            def yaml_context_attributes
              {
                variables: context.variables,
                component: context.component_data
              }
            end

            def parsed_content_blank?
              content_result.content.blank?
            end
            strong_memoize_attr :parsed_content_blank?

            def expanded_content_hash
              return if parsed_content_blank?

              strong_memoize(:expanded_content_hash) do
                expand_includes(content_result.content)
              end
            end

            def validate_parsed_content_presence!
              # Expanding `include:` can legitimately yield an empty hash, for example when every
              # nested include is dropped by its `include:rules:`, so the expanded result cannot be
              # validated here.
              return unless parsed_content_blank?

              errors.push("Included file `#{masked_location}` contains no configuration!")
            end

            def expand_includes(hash)
              return hash if inputs_only?

              External::Processor.new(hash, expanded_context).perform
            end

            def expand_context_attrs
              { parent_file: self }
            end

            def masked_location
              strong_memoize(:masked_location) do
                context.mask_variables_from(location)
              end
            end

            def log_and_raise_timeout_error
              log_gitaly_timeout

              raise Context::TimeoutError, 'CI configuration fetch from Gitaly timed out. ' \
                'This may indicate Gitaly service slowness or an outage.'
            end

            def log_gitaly_timeout
              Gitlab::AppJsonLogger.warn(
                class: self.class.name,
                message: 'CI config Gitaly request timed out',
                project_id: context.project&.id,
                extra: { timeout_s: Config::GITALY_TIMEOUT_SECONDS, location: masked_location }
              )
            end
          end
        end
      end
    end
  end
end
