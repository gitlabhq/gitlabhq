# frozen_string_literal: true

class Release < ApplicationRecord
  include Presentable
  include CacheMarkdownField
  include Importable
  include Gitlab::Utils::StrongMemoize

  cache_markdown_field :description

  belongs_to :project
  # releases prior to 11.7 have no author
  belongs_to :author, class_name: 'User'

  has_many :links, class_name: 'Releases::Link'

  has_many :milestone_releases
  has_many :milestones, through: :milestone_releases
  has_many :evidences, inverse_of: :release, class_name: 'Releases::Evidence'

  default_value_for :released_at, allows_nil: false do
    Time.zone.now
  end

  accepts_nested_attributes_for :links, allow_destroy: true

  validates :project, :tag, presence: true
  validates_associated :milestone_releases, message: -> (_, obj) { obj[:value].map(&:errors).map(&:full_messages).join(",") }

  scope :sorted, -> { order(released_at: :desc) }
  scope :preloaded, -> { includes(:evidences, :milestones, project: [:project_feature, :route, { namespace: :route }]) }
  scope :with_project_and_namespace, -> { includes(project: :namespace) }
  scope :recent, -> { sorted.limit(MAX_NUMBER_TO_DISPLAY) }

  delegate :repository, to: :project

  MAX_NUMBER_TO_DISPLAY = 3

  def to_param
    CGI.escape(tag)
  end

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
    released_at.present? && released_at.to_i > Time.zone.now.to_i
  end

  def historical_release?
    released_at.present? && released_at.to_i < created_at.to_i
  end

  def name
    self.read_attribute(:name) || tag
  end

  def milestone_titles
    self.milestones.map {|m| m.title }.sort.join(", ")
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

Release.prepend_if_ee('EE::Release')
