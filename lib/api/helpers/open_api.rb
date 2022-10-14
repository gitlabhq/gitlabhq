# frozen_string_literal: true

module API
  module Helpers
    module OpenApi
      extend ActiveSupport::Concern

      class_methods do
        def add_open_api_documentation!
          return if Rails.env.production?

          open_api_config = YAML.load_file(Rails.root.join('config/open_api.yml'))['metadata'].deep_symbolize_keys

          add_swagger_documentation(open_api_config)
        end
      end
    end
  end
end
