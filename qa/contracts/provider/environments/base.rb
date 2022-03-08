# frozen_string_literal: true

require 'faraday'

module Environments
  class Base
    attr_writer :base_url, :merge_request

    def call(env)
      @payload
    end

    def http(endpoint)
      Faraday.default_adapter = :net_http
      response = Faraday.get(@base_url + endpoint)
      @payload = [response.status, response.headers, [response.body]]
      self
    end

    def merge_request(endpoint)
      if endpoint.include? '.json'
        http(@merge_request + endpoint)
      end
    end
  end
end
