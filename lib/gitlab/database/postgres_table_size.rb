# frozen_string_literal: true

module Gitlab
  module Database
    class PostgresTableSize < SharedModel
      SMALL = 10.gigabytes
      MEDIUM = 50.gigabytes
      LARGE = 100.gigabytes
      ALERT = 25.gigabytes

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
      scope :alerting, -> { where(size_in_bytes: ALERT...) }

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

      def alert_report_hash
        {
          identifier: identifier,
          schema_name: schema_name,
          table_name: table_name,
          total_size: total_size,
          table_size: table_size,
          index_size: index_size,
          size_in_bytes: size_in_bytes,
          classification: size_classification
        }
      end
    end
  end
end
