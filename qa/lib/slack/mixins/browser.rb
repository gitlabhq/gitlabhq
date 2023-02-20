# frozen_string_literal: true

module Slack
  module Mixins
    module Browser
      def browser
        ::Chemlab.configuration.browser.session.engine
      end
    end
  end
end
