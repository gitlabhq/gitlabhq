# frozen_string_literal: true

module Gitlab
  module Database
    class PostgresTableSize < SharedModel
      SMALL = 10.gigabytes
      MEDIUM = 50.gigabytes
      LARGE = 100.gigabytes

      CLASSIFICATION = {
        small: 0...SMALL,
        medium: SMALL...MEDIUM,
        large: MEDIUM...LARGE,
        over_limit: LARGE...
      }.freeze

      self.primary_key = 'identifier'
      self.table_name = 'postgres_table_sizes'

      scope :small, -> { where(size_in_bytes: CLASSIFICATION[:small]) }
      scope :medium, -> { where(size_in_bytes: CLASSIFICATION[:medium]) }
      scope :large, -> { where(size_in_bytes: CLASSIFICATION[:large]) }
      scope :over_limit, -> { where(size_in_bytes: CLASSIFICATION[:over_limit]) }

      def self.by_table_name(table_name)
        where(table_name: table_name).first
      end

      def size_classification
        case size_in_bytes
        when CLASSIFICATION[:small]
          'small'
        when CLASSIFICATION[:medium]
          'medium'
        when CLASSIFICATION[:large]
          'large'
        when CLASSIFICATION[:over_limit]
          'over_limit'
        end
      end
    end
  end
end
