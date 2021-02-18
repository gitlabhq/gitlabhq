# frozen_string_literal: true

module Gitlab
  module Ci
    class Config
      module Yaml
        AVAILABLE_TAGS = [Config::Yaml::Tags::Reference].freeze

        class << self
          def load!(content)
            ensure_custom_tags

            Gitlab::Config::Loader::Yaml.new(content, additional_permitted_classes: AVAILABLE_TAGS).load!
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
