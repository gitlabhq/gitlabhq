# frozen_string_literal: true

require 'active_support/core_ext/integer/time'

module QA
  module Support
    module SystemLogs
      class Kibana
        BASE_URLS = {
          staging: 'https://nonprod-log.gitlab.net/',
          production: 'https://log.gprd.gitlab.net/',
          pre: 'https://nonprod-log.gitlab.net/'
        }.freeze
        INDICES = {
          staging: 'ed942d00-5186-11ea-ad8a-f3610a492295',
          production: '7092c4e2-4eb5-46f2-8305-a7da2edad090',
          pre: 'pubsub-rails-inf-pre'
        }.freeze
        DASHBOARD_IDS = {
          staging: 'b74dc030-6f56-11ed-9af2-6131f0ee4ce6',
          production: '5e6d3440-7597-11ed-9f43-e3784d7fe3ca',
          pre: '15596340-7570-11ed-9af2-6131f0ee4ce6'
        }.freeze

        def initialize(env, correlation_id)
          @base_url = BASE_URLS[env]
          @index = INDICES[env]
          @dashboard_id = DASHBOARD_IDS[env]
          @correlation_id = correlation_id
        end

        def discover_url
          return if @base_url.nil?

          "#{@base_url}app/discover#/?_a=%28index:%27#{@index}%27%2Cquery%3A%28language%3Akuery%2C" \
          "query%3A%27json.correlation_id%20%3A%20#{@correlation_id}%27%29%29" \
          "&_g=%28time%3A%28from%3A%27#{start_time}%27%2Cto%3A%27#{end_time}%27%29%29"
        end

        def dashboard_url
          return if @base_url.nil?

          "#{@base_url}app/dashboards#/view/#{@dashboard_id}?_g=%28time%3A%28from:%27#{start_time}%27%2C" \
          "to%3A%27#{end_time}%27%29%29&_a=%28filters%3A%21%28%28query%3A%28match_phrase%3A%28" \
          "json.correlation_id%3A%27#{@correlation_id}%27%29%29%29%29%29"
        end

        private

        def start_time
          (Time.now.utc - 24.hours).iso8601(3)
        end

        def end_time
          Time.now.utc.iso8601(3)
        end
      end
    end
  end
end
