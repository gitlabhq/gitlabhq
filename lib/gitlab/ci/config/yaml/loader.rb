# frozen_string_literal: true

module Gitlab
  module Ci
    class Config
      module Yaml
        class Loader
          AVAILABLE_TAGS = [Config::Yaml::Tags::Reference].freeze
          MAX_DOCUMENTS = 2

          def initialize(content, project: nil)
            @content = content
            @project = project
          end

          def to_result
            Yaml::Result.new(config: load!, error: nil)
          rescue ::Gitlab::Config::Loader::FormatError => e
            Yaml::Result.new(error: e)
          end

          private

          attr_reader :content, :project

          def ensure_custom_tags
            @ensure_custom_tags ||= begin
              AVAILABLE_TAGS.each { |klass| Psych.add_tag(klass.tag, klass) }

              true
            end
          end

          def load!
            ensure_custom_tags

            if project.present? && ::Feature.enabled?(:ci_multi_doc_yaml, project)
              ::Gitlab::Config::Loader::MultiDocYaml.new(
                content,
                max_documents: MAX_DOCUMENTS,
                additional_permitted_classes: AVAILABLE_TAGS,
                reject_empty: true
              ).load!
            else
              ::Gitlab::Config::Loader::Yaml
                .new(content, additional_permitted_classes: AVAILABLE_TAGS)
                .load!
            end
          end
        end
      end
    end
  end
end
