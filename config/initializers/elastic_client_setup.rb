# Be sure to restart your server when you modify this file.

require 'gitlab/current_settings'

module Elasticsearch
  module Model
    module Client
      module ClassMethods
        include Gitlab::CurrentSettings

        def client(client = nil)
          if @client.nil? || es_configuration_changed?
            @es_host = current_application_settings.elasticsearch_host
            @es_port = current_application_settings.elasticsearch_port

            @client = Elasticsearch::Client.new(
              host: current_application_settings.elasticsearch_host,
              port: current_application_settings.elasticsearch_port
            )
          end

          @client
        end

        def es_configuration_changed?
          @es_host != current_application_settings.elasticsearch_host ||
          @es_port != current_application_settings.elasticsearch_port
        end
      end
    end
  end
end
