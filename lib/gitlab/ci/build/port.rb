# frozen_string_literal: true

module Gitlab
  module Ci
    module Build
      class Port
        DEFAULT_PORT_NAME = 'default_port'
        DEFAULT_PORT_PROTOCOL = 'http'

        attr_reader :number, :protocol, :name

        def initialize(port)
          @name = DEFAULT_PORT_NAME
          @protocol = DEFAULT_PORT_PROTOCOL

          case port
          when Integer
            @number = port
          when Hash
            @number = port[:number]
            @protocol = port.fetch(:protocol, @protocol)
            @name = port.fetch(:name, @name)
          end
        end

        def valid?
          @number.present?
        end
      end
    end
  end
end
