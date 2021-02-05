# frozen_string_literal: true

module Gitlab
  module Usage
    module Docs
      class Renderer
        include Gitlab::Usage::Docs::Helper
        DICTIONARY_PATH = Rails.root.join('doc', 'development', 'usage_ping')
        TEMPLATE_PATH = Rails.root.join('lib', 'gitlab', 'usage', 'docs', 'templates', 'default.md.haml')

        def initialize(metrics_definitions)
          @layout = Haml::Engine.new(File.read(TEMPLATE_PATH))
          @metrics_definitions = metrics_definitions.sort
        end

        def contents
          # Render and remove an extra trailing new line
          @contents ||= @layout.render(self, metrics_definitions: @metrics_definitions).sub!(/\n(?=\Z)/, '')
        end

        def write
          filename = DICTIONARY_PATH.join('dictionary.md').to_s

          FileUtils.mkdir_p(DICTIONARY_PATH)
          File.write(filename, contents)

          filename
        end
      end
    end
  end
end
