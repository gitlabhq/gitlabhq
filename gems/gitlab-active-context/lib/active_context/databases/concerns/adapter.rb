# frozen_string_literal: true

module ActiveContext
  module Databases
    module Concerns
      module Adapter
        attr_reader :client

        delegate :search, to: :client

        def initialize(options)
          @client = client_klass.new(options)
        end

        def client_klass
          raise NotImplementedError
        end
      end
    end
  end
end
