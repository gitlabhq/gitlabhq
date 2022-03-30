# frozen_string_literal: true

class RepositoryLanguage < ApplicationRecord
  extend SuppressCompositePrimaryKeyWarning

  belongs_to :project
  belongs_to :programming_language

  default_scope { includes(:programming_language) } # rubocop:disable Cop/DefaultScope

  scope :with_programming_language, ->(*names) do
    joins(:programming_language).merge(ProgrammingLanguage.with_name_case_insensitive(*names))
  end

  validates :project, presence: true
  validates :share, inclusion: { in: 0..100, message: "The share of a language is between 0 and 100" }
  validates :programming_language, uniqueness: { scope: :project_id }

  delegate :name, :color, to: :programming_language
end
