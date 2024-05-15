# frozen_string_literal: true

module Ci
  module Partitionable
    class Organizer
      class << self
        def create_database_partition?(database_partition)
          database_partition.before?(Ci::Pipeline::NEXT_PARTITION_VALUE)
        end
      end
    end
  end
end
