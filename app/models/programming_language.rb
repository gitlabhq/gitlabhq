# frozen_string_literal: true

class ProgrammingLanguage < ApplicationRecord
  validates :name, presence: true
  validates :color, allow_blank: false, color: true

  # Returns all programming languages which match any of the given names (case
  # insensitively).
  scope :with_name_case_insensitive, ->(*names) do
    sanitized_names = names.map(&method(:sanitize_sql_like))
    where(arel_table[:name].matches_any(sanitized_names))
  end
end
