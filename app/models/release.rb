# frozen_string_literal: true

class Release < ApplicationRecord
  include Presentable
  include CacheMarkdownField
  include Importable
  include Gitlab::Utils::StrongMemoize

  cache_markdown_field :description

  belongs_to :project, touch: true
  # releases prior to 11.7 have no author
  belongs_to :author, class_name: 'User'

  has_many :links, class_name: 'Releases::Link'
  has_many :sorted_links, -> { sorted }, class_name: 'Releases::Link', inverse_of: :release

  has_many :milestone_releases
  has_many :milestones, through: :milestone_releases
  has_many :evidences, inverse_of: :release, class_name: 'Releases::Evidence'

  accepts_nested_attributes_for :links, allow_destroy: true

  before_create :set_released_at

  validates :project, :tag, presence: true
  validates :description, length: { maximum: Gitlab::Database::MAX_TEXT_SIZE_LIMIT }, if: :description_changed?
  validates_associated :milestone_releases, message: -> (_, obj) { obj[:value].map(&:errors).map(&:full_messages).join(",") }
  validates :links, nested_attributes_duplicates: { scope: :release, child_attributes: %i[name url filepath] }

  scope :sorted, -> { order(released_at: :desc) }
  scope :preloaded, -> {
    includes(:author, :evidences, :milestones, :links, :sorted_links,
             project: [:project_feature, :route, { namespace: :route }])
  }
  scope :with_project_and_namespace, -> { includes(project: :namespace) }
  scope :recent, -> { sorted.limit(MAX_NUMBER_TO_DISPLAY) }
  scope :without_evidence, -> { left_joins(:evidences).where(::Releases::Evidence.arel_table[:id].eq(nil)) }
  scope :released_within_2hrs, -> { where(released_at: Time.zone.now - 1.hour..Time.zone.now + 1.hour) }

  # Sorting
  scope :order_created, -> { reorder(created_at: :asc) }
  scope :order_created_desc, -> { reorder(created_at: :desc) }
  scope :order_released, -> { reorder(released_at: :asc) }
  scope :order_released_desc, -> { reorder(released_at: :desc) }

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
    links_count = links.size
    sources_count = except.include?(:sources) ? 0 : sources.size

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
    self.milestones.order_by_dates_and_title.map {|m| m.title }.join(', ')
  end

  def to_hook_data(action)
    Gitlab::HookData::ReleaseBuilder.new(self).build(action)
  end

  def execute_hooks(action)
    hook_data = to_hook_data(action)
    project.execute_hooks(hook_data, :release_hooks)
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

  def set_released_at
    self.released_at ||= created_at
  end

  def self.sort_by_attribute(method)
    case method.to_s
    when 'created_at_asc' then order_created
    when 'created_at_desc' then order_created_desc
    when 'released_at_asc' then order_released
    when 'released_at_desc' then order_released_desc
    else
      order_created_desc
    end
  end
end

Release.prepend_mod_with('Release')
