# frozen_string_literal: true

module Gitlab
  module Database
    module BackgroundMigration
      class SubBatchTimeoutError < StandardError
        def initialize(caused_by)
          @caused_by = caused_by

          super(caused_by)
        end

        attr_reader :caused_by
      end
    end
  end
end
