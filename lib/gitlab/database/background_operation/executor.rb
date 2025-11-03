# frozen_string_literal: true

module Gitlab
  module Database
    module BackgroundOperation
      class Executor
        def initialize(connection:)
          @connection = connection
        end

        def perform(_job); end
      end
    end
  end
end
