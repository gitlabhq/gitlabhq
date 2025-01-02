# frozen_string_literal: true

module ActiveContext
  module Databases
    module Postgresql
      class Adapter
        include ActiveContext::Databases::Concerns::Adapter

        def client_klass
          ActiveContext::Databases::Postgresql::Client
        end
      end
    end
  end
end
