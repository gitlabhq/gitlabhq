# frozen_string_literal: true

module ActiveContext
  module Databases
    module Postgresql
      class Adapter
        include ActiveContext::Databases::Concerns::Adapter

        delegate :bulk_process, to: :client

        def name
          'postgresql'
        end

        def client_klass
          ActiveContext::Databases::Postgresql::Client
        end

        def indexer_klass
          ActiveContext::Databases::Postgresql::Indexer
        end

        def executor_klass
          ActiveContext::Databases::Postgresql::Executor
        end

        def indexer_connection_options
          Config.build_database_config(options).slice(:host, :port, :user, :password, :database)
        end
      end
    end
  end
end
