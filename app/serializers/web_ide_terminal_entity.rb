# frozen_string_literal: true

class WebIdeTerminalEntity < Grape::Entity
  expose :id
  expose :status
  expose :show_path
  expose :cancel_path
  expose :retry_path
  expose :terminal_path
  expose :services
  expose :proxy_websocket_path, if: ->(_) { Feature.enabled?(:build_service_proxy) }
end
