class RepositoryLanguage < ActiveRecord::Base
  belongs_to :project
  belongs_to :programming_language

  default_scope { includes(:programming_language) }

  validates :project, presence: true
  validates :share, inclusion: { in: 0..100, message: "The share of a lanuage is between 0 and 100" }
  validates :programming_language, uniqueness: { scope: :project_id }

  delegate :name, :color, to: :programming_language
end
