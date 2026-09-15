# frozen_string_literal: true

module Gitlab
  module Markdown
    module IframeProviders
      PERMITTED_SANDBOX_FLAGS = %w[
        allow-scripts
        allow-same-origin
        allow-popups
        allow-popups-to-escape-sandbox
        allow-presentation
      ].freeze

      PLACEHOLDER = /\{(\w+)\}/

      ConfigError = Class.new(StandardError)
    end
  end
end
