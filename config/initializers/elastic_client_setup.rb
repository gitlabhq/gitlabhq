# Be sure to restart your server when you modify this file.

require 'gitlab/current_settings'

module Elasticsearch
  module Model
    module Client
      module ClassMethods
        include Gitlab::CurrentSettings

        def client(client = nil)
          if @client.nil? || es_configuration_changed?
            @es_config = current_application_settings.elasticsearch_config
            @client = ::Gitlab::Elastic::Client.build(@es_config)
          end

          @client
        end

        def es_configuration_changed?
          @es_config != current_application_settings.elasticsearch_config
        end
      end
    end
  end
end
