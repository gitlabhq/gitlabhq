# frozen_string_literal: true

module Gitlab
  module Database
    class PostgresTableSize < SharedModel
      SMALL = 10.gigabytes
      MEDIUM = 50.gigabytes
      LARGE = 100.gigabytes

      self.primary_key = 'identifier'
      self.table_name = 'postgres_table_sizes'

      scope :small, -> { where(size_in_bytes: ...SMALL) }
      scope :medium, -> { where(size_in_bytes: SMALL...MEDIUM) }
      scope :large, -> { where(size_in_bytes: MEDIUM...LARGE) }
      scope :over_limit, -> { where(size_in_bytes: LARGE...) }
    end
  end
end
