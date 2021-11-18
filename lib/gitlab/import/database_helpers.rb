# frozen_string_literal: true

module Gitlab
  module Import
    module DatabaseHelpers
      # Inserts a raw row and returns the ID of the inserted row.
      #
      # attributes - The attributes/columns to set.
      # relation - An ActiveRecord::Relation to use for finding the table name
      def insert_and_return_id(attributes, relation)
        # We use bulk_insert here so we can bypass any queries executed by
        # callbacks or validation rules, as doing this wouldn't scale when
        # importing very large projects.
        result = ApplicationRecord # rubocop:disable Gitlab/BulkInsert
                 .legacy_bulk_insert(relation.table_name, [attributes], return_ids: true)

        result.first
      end
    end
  end
end
