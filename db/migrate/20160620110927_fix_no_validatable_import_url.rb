# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class FixNoValidatableImportUrl < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers
  class SqlBatches

    attr_reader :results, :query

    def initialize(batch_size: 100, query:)
      @offset = 0
      @batch_size = batch_size
      @query = query
      @results = []
    end

    def next
      @results = ActiveRecord::Base.connection.execute(batched_sql)
      @offset += @batch_size
      @results.any?
    end

    private

    def batched_sql
      "#{@query} OFFSET #{@offset} LIMIT #{@batch_size}"
    end
  end

  def up
    invalid_import_url_project_ids.each { |project_id| cleanup_import_url(project_id) }
  end

  def invalid_import_url_project_ids
    ids = []
    batches = SqlBatches.new(query: "SELECT id, import_url FROM projects WHERE import_url IS NOT NULL")

    while batches.nexts
      ids += batches.results.map { |result| invalid_url?(result[:import_url]) ? result[:id] : nil }
    end

    ids.compact
  end

  def invalid_url?(url)
    AddressableUrlValidator.new({ attributes: 1 }).valid_url?(url)
  end

  def cleanup_import_url(project_id)
    execute("UPDATE projects SET mirror = false, import_url = NULL WHERE id = #{project_id}")
  end
end
