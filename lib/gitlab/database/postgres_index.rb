# frozen_string_literal: true

module Gitlab
  module Database
    class PostgresIndex < ActiveRecord::Base
      self.table_name = 'postgres_indexes'
      self.primary_key = 'identifier'

      scope :by_identifier, ->(identifier) do
        raise ArgumentError, "Index name is not fully qualified with a schema: #{identifier}" unless identifier =~ /^\w+\.\w+$/

        find(identifier)
      end

      # A 'regular' index is a non-unique index,
      # that does not serve an exclusion constraint and
      # is defined on a table that is not partitioned.
      scope :regular, -> { where(unique: false, partitioned: false, exclusion: false)}

      scope :random_few, ->(how_many) do
        limit(how_many).order(Arel.sql('RANDOM()'))
      end

      scope :not_match, ->(regex) { where("name !~ ?", regex)}

      def to_s
        name
      end
    end
  end
end
