# frozen_string_literal: true

module Gitlab
  module FogbugzImport
    class HttpAdapter
      def initialize(options = {})
        @root_url = options[:uri]
      end

      def request(action, options = {})
        uri = Gitlab::Utils.append_path(@root_url, 'api.asp')

        params = { 'cmd' => action }.merge(options.fetch(:params, {}))

        response = Gitlab::HTTP.post(uri, body: params)

        response.body
      end
    end
  end
end
