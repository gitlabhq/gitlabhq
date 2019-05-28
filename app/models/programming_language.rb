# frozen_string_literal: true

class ProgrammingLanguage < ApplicationRecord
  validates :name, presence: true
  validates :color, allow_blank: false, color: true

  # Returns all programming languages which match the given name (case
  # insensitively).
  scope :with_name_case_insensitive, ->(name) do
    where(arel_table[:name].matches(sanitize_sql_like(name)))
  end
end
