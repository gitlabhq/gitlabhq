# frozen_string_literal: true

class Release < ApplicationRecord
  include Presentable
  include CacheMarkdownField
  include Importable
  include Gitlab::Utils::StrongMemoize
  include EachBatch
  include FromUnion
  include UpdatedAtFilterable

  cache_markdown_field :description

  belongs_to :project, touch: true
  belongs_to :author, class_name: 'User'

  has_many :links, class_name: 'Releases::Link'
  has_many :sorted_links, -> { sorted }, class_name: 'Releases::Link', inverse_of: :release

  has_many :milestone_releases
  has_many :milestones, through: :milestone_releases
  has_many :evidences, inverse_of: :release, class_name: 'Releases::Evidence'

  has_one :catalog_resource_version, class_name: 'Ci::Catalog::Resources::Version', inverse_of: :release

  accepts_nested_attributes_for :links, allow_destroy: true

  before_create :set_released_at
  after_update :update_catalog_resource_version, if: -> { catalog_resource_version && saved_change_to_released_at? }
  after_destroy :update_catalog_resource, if: -> { project.catalog_resource }

  validates :project, :tag, presence: true
  validates :author_id, presence: true, on: :create

  validates :tag, uniqueness: { scope: :project_id }

  validates :description, length: { maximum: Gitlab::Database::MAX_TEXT_SIZE_LIMIT }, if: :description_changed?
  validates_associated :milestone_releases, message: ->(_, obj) { obj[:value].map(&:errors).map(&:full_messages).join(",") }
  validates :links, nested_attributes_duplicates: { scope: :release, child_attributes: %i[name url filepath] }

  # Custom validation methods
  validate :sha_unchanged, on: :update

  # All releases should have tags, but because of existing invalid data, we need a work around so that presenters don't
  # fail to generate URLs on release related pages
  scope :tagged, -> { where.not(tag: [nil, '']) }

  scope :sorted, -> { order(released_at: :desc) }
  scope :preloaded, -> {
    includes(
      :author, :evidences, :milestones, :links, :sorted_links,
      project: [:project_feature, :route, { namespace: :route }]
    )
  }
  scope :with_milestones, -> { joins(:milestone_releases) }
  scope :with_group_milestones, -> { joins(:milestones).where.not(milestones: { group_id: nil }) }
  scope :recent, -> { sorted.limit(MAX_NUMBER_TO_DISPLAY) }
  scope :without_evidence, -> { left_joins(:evidences).where(::Releases::Evidence.arel_table[:id].eq(nil)) }
  scope :released_within_2hrs, -> { where(released_at: Time.zone.now - 1.hour..Time.zone.now + 1.hour) }
  scope :unpublished, -> { where(release_published_at: nil) }
  scope :for_projects, ->(projects) { where(project_id: projects) }
  scope :by_tag, ->(tag) { where(tag: tag) }

  # Sorting
  scope :order_created, -> { reorder(created_at: :asc) }
  scope :order_created_desc, -> { reorder(created_at: :desc) }
  scope :order_released, -> { reorder(released_at: :asc) }
  scope :order_released_desc, -> { reorder(released_at: :desc) }

  delegate :repository, to: :project

  MAX_NUMBER_TO_DISPLAY = 3
  MAX_NUMBER_TO_PUBLISH = 5000

  class << self
    # In the future, we should support `order_by=semver`;
    # see https://gitlab.com/gitlab-org/gitlab/-/issues/352945
    def latest(order_by: 'released_at')
      sort_by_attribute("#{order_by}_desc").first
    end

    # This query uses LATERAL JOIN to find the latest release for each project. To avoid
    # joining the `projects` table, we build an in-memory table using the project ids.
    # Example:
    # SELECT ...
    # FROM (VALUES (PROJECT_ID_1),(PROJECT_ID_2)) projects (id)
    # INNER JOIN LATERAL (...)
    def latest_for_projects(projects, order_by: 'released_at')
      return Release.none if projects.empty?

      projects_table = Project.arel_table
      releases_table = Release.arel_table

      join_query = Release
        .where(projects_table[:id].eq(releases_table[:project_id]))
        .sort_by_attribute("#{order_by}_desc")
        .limit(1)

      project_ids_list = projects.map { |project| "(#{project.id})" }.join(',')

      Release
        .from("(VALUES #{project_ids_list}) projects (id)")
        .joins("INNER JOIN LATERAL (#{join_query.to_sql}) #{Release.table_name} ON TRUE")
    end

    def waiting_for_publish_event
      unpublished.released_within_2hrs.joins(:project).merge(Project.with_feature_enabled(:releases)).limit(MAX_NUMBER_TO_PUBLISH)
    end
  end

  def sha_unchanged
    errors.add(:sha, "cannot be changed") if sha_changed?
  end

  def to_param
    tag
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
    self.milestones.order_by_dates_and_title.map { |m| m.title }.join(', ')
  end

  def to_hook_data(action)
    Gitlab::HookData::ReleaseBuilder.new(self).build(action)
  end

  def execute_hooks(action)
    hook_data = to_hook_data(action)
    project.execute_hooks(hook_data, :release_hooks)
  end

  def related_deployments
    Deployment
      .with(Gitlab::SQL::CTE.new(:available_environments, project.environments.available.select(:id)).to_arel)
      .where('environment_id IN (SELECT * FROM available_environments)')
      .where(ref: tag)
      .with_environment_page_associations
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

  def update_catalog_resource_version
    catalog_resource_version.sync_with_release!
  end

  def update_catalog_resource
    project.catalog_resource.update_latest_released_at!
  end
end

Release.prepend_mod_with('Release')
