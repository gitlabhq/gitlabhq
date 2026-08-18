# frozen_string_literal: true

class RepositoryLanguage < ApplicationRecord
  belongs_to :project
  belongs_to :programming_language

  default_scope { includes(:programming_language) } # rubocop:disable Cop/DefaultScope

  scope :with_programming_language, ->(*names) do
    joins(:programming_language).merge(ProgrammingLanguage.with_name_case_insensitive(*names))
  end

  validates :project, presence: true
  validates :share, inclusion: { in: 0..100, message: "The share of a language is between 0 and 100" }
  validates :programming_language, uniqueness: { scope: :project_id }
  # language_id can remain NULL until instances complete the cleanup and NOT NULL rollout. PostgreSQL unique indexes
  # permit multiple NULLs, so validation must do the same. allow_nil: true will be removed as part of
  # https://gitlab.com/gitlab-org/gitlab/-/work_items/614144.
  validates :language_id, uniqueness: { scope: :project_id }, allow_nil: true

  delegate :name, :color, to: :programming_language
end
