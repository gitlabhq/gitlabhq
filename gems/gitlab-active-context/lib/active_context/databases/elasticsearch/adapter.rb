# frozen_string_literal: true

module ActiveContext
  module Databases
    module Elasticsearch
      class Adapter
        include ActiveContext::Databases::Concerns::Adapter

        def client_klass
          ActiveContext::Databases::Elasticsearch::Client
        end
      end
    end
  end
end
