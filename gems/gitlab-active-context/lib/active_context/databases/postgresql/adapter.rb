# frozen_string_literal: true

module ActiveContext
  module Databases
    module Postgresql
      class Adapter
        include ActiveContext::Databases::Concerns::Adapter

        def client_klass
          ActiveContext::Databases::Postgresql::Client
        end

        def indexer_klass
          ActiveContext::Databases::Postgresql::Indexer
        end

        def executor_klass
          ActiveContext::Databases::Postgresql::Executor
        end
      end
    end
  end
end
