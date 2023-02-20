# frozen_string_literal: true

module Gitlab
  module Ci
    class Config
      module Yaml
        AVAILABLE_TAGS = [Config::Yaml::Tags::Reference].freeze
        MAX_DOCUMENTS = 2

        class << self
          def load!(content)
            ensure_custom_tags

            if ::Feature.enabled?(:ci_multi_doc_yaml)
              Gitlab::Config::Loader::MultiDocYaml.new(
                content,
                max_documents: MAX_DOCUMENTS,
                additional_permitted_classes: AVAILABLE_TAGS
              ).load!.first
            else
              Gitlab::Config::Loader::Yaml.new(content, additional_permitted_classes: AVAILABLE_TAGS).load!
            end
          end

          private

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
