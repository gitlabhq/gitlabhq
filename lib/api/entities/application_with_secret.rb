# frozen_string_literal: true

module API
  module Entities
    # Use with care, this exposes the secret
    class ApplicationWithSecret < Entities::Application
      expose :secret, documentation: {
        type: 'String',
        example: 'ee1dd64b6adc89cf7e2c23099301ccc2c61b441064e9324d963c46902a85ec34'
      } do |application, _options|
        application.plaintext_secret
      end
      expose :warnings, if: ->(_, options) { options[:warnings].present? },
        documentation: {
          type: 'String', is_array: true,
          example: ['Tokens cannot use the MCP server without a user-level scope granting execute_mcp_tool.']
        } do |_, options|
        options[:warnings]
      end
    end
  end
end
