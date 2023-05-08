# frozen_string_literal: true

module Projects
  module Aws
    class ConfigurationController < Projects::Aws::BaseController
      def index
        js_data = {}
        @js_data = Gitlab::Json.dump(js_data)
        track_event(:render_page)
      end
    end
  end
end
