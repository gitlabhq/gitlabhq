# frozen_string_literal: true

module Gitlab
  module Tracking
    module Docs
      class Renderer
        include Gitlab::Tracking::Docs::Helper
        DICTIONARY_PATH = Rails.root.join('doc', 'development', 'snowplow')
        TEMPLATE_PATH = Rails.root.join('lib', 'gitlab', 'tracking', 'docs', 'templates', 'default.md.haml')

        def initialize(event_definitions)
          @layout = Haml::Engine.new(File.read(TEMPLATE_PATH))
          @event_definitions = event_definitions.sort
        end

        def contents
          # Render and remove an extra trailing new line
          @contents ||= @layout.render(self, event_definitions: @event_definitions).sub!(/\n(?=\Z)/, '')
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
