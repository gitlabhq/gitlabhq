# frozen_string_literal: true

class Release < ApplicationRecord
  include CacheMarkdownField
  include Gitlab::Utils::StrongMemoize

  cache_markdown_field :description

  belongs_to :project
  # releases prior to 11.7 have no author
  belongs_to :author, class_name: 'User'

  has_many :links, class_name: 'Releases::Link'

  # A one-to-one relationship is set up here as part of a MVC: https://gitlab.com/gitlab-org/gitlab-ce/issues/62402
  # However, on the long term, we will want a many-to-many relationship between Release and Milestone.
  # The "has_one through" allows us today to set up this one-to-one relationship while setting up the architecture for the long-term (ie intermediate table).
  has_one :milestone_release
  has_one :milestone, through: :milestone_release

  default_value_for :released_at, allows_nil: false do
    Time.zone.now
  end

  accepts_nested_attributes_for :links, allow_destroy: true

  validates :description, :project, :tag, presence: true
  validates :name, presence: true, on: :create
  validates_associated :milestone_release, message: -> (_, obj) { obj[:value].errors.full_messages.join(",") }

  scope :sorted, -> { order(released_at: :desc) }

  delegate :repository, to: :project

  def commit
    strong_memoize(:commit) do
      repository.commit(actual_sha)
    end
  end

  def tag_missing?
    actual_tag.nil?
  end

  def assets_count(except: [])
    links_count = links.count
    sources_count = except.include?(:sources) ? 0 : sources.count

    links_count + sources_count
  end

  def sources
    strong_memoize(:sources) do
      Releases::Source.all(project, tag)
    end
  end

  def upcoming_release?
    released_at.present? && released_at > Time.zone.now
  end

  private

  def actual_sha
    sha || actual_tag&.dereferenced_target
  end

  def actual_tag
    strong_memoize(:actual_tag) do
      repository.find_tag(tag)
    end
  end
end
