# frozen_string_literal: true

module Gitlab
  module Ci
    class Config
      module Yaml
        class Loader
          include Gitlab::Utils::StrongMemoize

          AVAILABLE_TAGS = [Config::Yaml::Tags::Reference].freeze
          MAX_DOCUMENTS = 2

          def initialize(content, inputs: {}, current_user: nil)
            @content = content
            @current_user = current_user
            @inputs = inputs
          end

          def load
            yaml_result = load_uninterpolated_yaml

            return yaml_result unless yaml_result.valid?

            interpolator = Yaml::Interpolator.new(yaml_result, inputs, current_user: current_user)

            interpolator.interpolate!

            if interpolator.valid?
              # This Result contains only the interpolated config and does not have a header
              Yaml::Result.new(config: interpolator.to_hash, error: nil)
            else
              Yaml::Result.new(error: interpolator.error_message)
            end
          end

          private

          attr_reader :content, :current_user, :inputs

          def load_uninterpolated_yaml
            Yaml::Result.new(config: load_yaml!, error: nil)
          rescue ::Gitlab::Config::Loader::FormatError => e
            Yaml::Result.new(error: e.message, error_class: e)
          end

          def load_yaml!
            ensure_custom_tags

            ::Gitlab::Config::Loader::MultiDocYaml.new(
              content,
              max_documents: MAX_DOCUMENTS,
              additional_permitted_classes: AVAILABLE_TAGS,
              reject_empty: true
            ).load!
          end

          def ensure_custom_tags
            @ensure_custom_tags ||= begin
              AVAILABLE_TAGS.each { |klass| Psych.add_tag(klass.tag, klass) }

              true
            end
          end
        end
      end
    end
  end
end
