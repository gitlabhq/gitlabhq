# frozen_string_literal: true

require_relative 'utils/override'

module Gitlab
  class ExceptionsApp < ActionDispatch::PublicExceptions
    extend ::Gitlab::Utils::Override

    REQUEST_ID_PLACEHOLDER = '<!-- REQUEST_ID -->'
    REQUEST_ID_PARAGRAPH = '<p>Request ID: <code>%s</code></p>'

    override :call
    def call(env)
      status, headers, body = super

      if html_rendered? && body.first&.include?(REQUEST_ID_PLACEHOLDER)
        body = [insert_request_id(env, body.first)]
        headers['X-GitLab-Custom-Error'] = '1'
      end

      [status, headers, body]
    end

    private

    override :render_html
    def render_html(status)
      @html_rendered = true

      super
    end

    def html_rendered?
      !!@html_rendered
    end

    def insert_request_id(env, body)
      request_id = ERB::Util.html_escape(ActionDispatch::Request.new(env).request_id)

      body.gsub(REQUEST_ID_PLACEHOLDER, REQUEST_ID_PARAGRAPH % [request_id])
    end
  end
end
