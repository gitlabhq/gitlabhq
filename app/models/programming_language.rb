# frozen_string_literal: true

class ProgrammingLanguage < ApplicationRecord
  validates :name, presence: true
  validates :color, allow_blank: false, color: true

  # Returns all programming languages which match any of the given names (case
  # insensitively).
  scope :with_name_case_insensitive, ->(*names) do
    sanitized_names = names.map { |name| sanitize_sql_like(name) }
    where(arel_table[:name].matches_any(sanitized_names))
  end

  def self.most_popular(limit = 25)
    sql = <<~SQL
      SELECT
        mcv
      FROM
        pg_stats
      CROSS JOIN LATERAL
        unnest(most_common_vals::text::int[]) mt(mcv)
      WHERE
        tablename = 'repository_languages' and attname='programming_language_id'
      LIMIT
        $1
    SQL
    ids = connection.exec_query(sql, 'SQL', [limit]).rows.flatten

    where(id: ids).order(:name)
  end
end
