# frozen_string_literal: true

module Provider
  module Environments
    class Test
      def self.app
        Rack::Builder.app do
          map "/" do
            run Gitlab::Application
          end
        end
      end
    end
  end
end
