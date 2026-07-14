# frozen_string_literal: true

module Gitlab
  module Database
    module Partitioning
      module PartitionKeyColumnTypes
        INTEGER_TYPES = %w[integer bigint smallint].freeze
        DATE_TYPES = ['date', 'timestamp without time zone', 'timestamp with time zone'].freeze
      end
    end
  end
end
