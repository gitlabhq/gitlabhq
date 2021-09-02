# frozen_string_literal: true

class RemoveDuplicateDastSiteTokens < ActiveRecord::Migration[6.1]
  disable_ddl_transaction!

  class DastSiteToken < ApplicationRecord
    self.table_name = 'dast_site_tokens'
    self.inheritance_column = :_type_disabled

    scope :duplicates, -> do
      all_duplicates = select(:project_id, :url)
                         .distinct
                         .group(:project_id, :url)
                         .having('count(*) > 1')
                         .pluck('array_agg(id) as ids')

      duplicate_ids = extract_duplicate_ids(all_duplicates)

      where(id: duplicate_ids)
    end

    def self.extract_duplicate_ids(duplicates)
      duplicates.flat_map { |ids| ids.first(ids.size - 1) }
    end
  end

  def up
    DastSiteToken.duplicates.delete_all
  end

  def down
  end
end
