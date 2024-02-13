# frozen_string_literal: true

module Gitlab
  module Ci
    class Config
      module Yaml
        class Loader
          include Gitlab::Utils::StrongMemoize

          AVAILABLE_TAGS = [Config::Yaml::Tags::Reference].freeze
          MAX_DOCUMENTS = 2

          def initialize(content, inputs: {}, variables: [])
            @content = content
            @inputs = inputs
            @variables = variables
          end

          def load
            if Feature.disabled?(:ci_text_interpolation, Feature.current_request, type: :gitlab_com_derisk)
              return legacy_load
            end

            interpolator = Interpolation::TextInterpolator.new(yaml_documents, inputs, variables)

            interpolator.interpolate!

            if interpolator.valid?
              loaded_yaml = yaml(interpolator.to_result).load!

              Yaml::Result.new(config: loaded_yaml, error: nil, interpolated: interpolator.interpolated?)
            else
              Yaml::Result.new(error: interpolator.error_message, interpolated: interpolator.interpolated?)
            end
          rescue ::Gitlab::Config::Loader::FormatError => e
            Yaml::Result.new(error: e.message, error_class: e)
          end

          def load_uninterpolated_yaml
            Yaml::Result.new(config: load_yaml!, error: nil)
          rescue ::Gitlab::Config::Loader::FormatError => e
            Yaml::Result.new(error: e.message, error_class: e)
          end

          private

          attr_reader :content, :inputs, :variables

          def yaml(content)
            ensure_custom_tags

            ::Gitlab::Config::Loader::Yaml.new(content, additional_permitted_classes: AVAILABLE_TAGS)
          end

          def yaml_documents
            docs = content
              .split(::Gitlab::Config::Loader::MultiDocYaml::MULTI_DOC_DIVIDER, MAX_DOCUMENTS + 1)
              .map { |d| yaml(d) }

            docs.reject!(&:blank?)

            Yaml::Documents.new(docs)
          end

          def legacy_load
            yaml_result = load_uninterpolated_yaml

            return yaml_result unless yaml_result.valid?

            interpolator = Interpolation::Interpolator.new(yaml_result, inputs, variables)

            interpolator.interpolate!

            if interpolator.valid?
              Yaml::Result.new(config: interpolator.to_hash, error: nil, interpolated: interpolator.interpolated?)
            else
              Yaml::Result.new(error: interpolator.error_message, interpolated: interpolator.interpolated?)
            end
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
