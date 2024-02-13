# frozen_string_literal: true

module CloudConnector
  module Config
    extend self

    def base_url
      Gitlab.config.cloud_connector.base_url
    end
  end
end
