# Be sure to restart your server when you modify this file.

require 'gitlab/current_settings'

Gitlab.ee do
  Elasticsearch::Model::Response::Records.prepend GemExtensions::Elasticsearch::Model::Response::Records
  Elasticsearch::Model::Adapter::Multiple::Records.prepend GemExtensions::Elasticsearch::Model::Adapter::Multiple::Records
  Elasticsearch::Model::Indexing::InstanceMethods.prepend GemExtensions::Elasticsearch::Model::Indexing::InstanceMethods

  module Elasticsearch
    module Model
      module Client
        # This mutex is only used to synchronize *creation* of a new client, so
        # all including classes can share the same client instance
        CLIENT_MUTEX = Mutex.new

        cattr_accessor :cached_client
        cattr_accessor :cached_config

        module ClassMethods
          # Override the default ::Elasticsearch::Model::Client implementation to
          # return a client configured from application settings. All including
          # classes will use the same instance, which is refreshed automatically
          # if the settings change.
          #
          # _client is present to match the arity of the overridden method, where
          # it is also not used.
          #
          # @return [Elasticsearch::Transport::Client]
          def client(_client = nil)
            store = ::Elasticsearch::Model::Client

            store::CLIENT_MUTEX.synchronize do
              config = Gitlab::CurrentSettings.elasticsearch_config

              if store.cached_client.nil? || config != store.cached_config
                store.cached_client = ::Gitlab::Elastic::Client.build(config)
                store.cached_config = config
              end
            end

            store.cached_client
          end
        end
      end
    end
  end
end
