# frozen_string_literal: true

class BackfillImportedSnippetRepositories < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  DELAY_INTERVAL = 2.minutes.to_i
  BATCH_SIZE = 200
  MIGRATION = 'BackfillSnippetRepositories'

  disable_ddl_transaction!

  class Snippet < ActiveRecord::Base
    include EachBatch

    self.table_name = 'snippets'
    self.inheritance_column = :_type_disabled
  end

  class SnippetRepository < ActiveRecord::Base
    self.table_name = 'snippet_repositories'
  end

  def up
    index = 1

    Snippet.select(:id).where.not(id: SnippetRepository.select(:snippet_id)).each_batch(of: BATCH_SIZE, column: 'id') do |batch|
      split_in_consecutive_batches(batch).each do |ids_batch|
        migrate_in(index * DELAY_INTERVAL, MIGRATION, [ids_batch.first, ids_batch.last])

        index += 1
      end
    end
  end

  def down
    # no-op
  end

  private

  def split_in_consecutive_batches(relation)
    ids = relation.pluck(:id)

    (ids.first..ids.last).to_a.split {|i| !ids.include?(i) }.select(&:present?)
  end
end
