require 'carrierwave/orm/activerecord'

class Project < ActiveRecord::Base
  include Gitlab::ConfigHelper
  include Gitlab::ShellAdapter
  include Gitlab::VisibilityLevel
  include Gitlab::CurrentSettings
  include AccessRequestable
  include CacheMarkdownField
  include Referable
  include Sortable
  include AfterCommitQueue
  include CaseSensitivity
  include TokenAuthenticatable
  include ProjectFeaturesCompatibility
  include SelectForProjectAuthorization

  extend Gitlab::ConfigHelper

  class BoardLimitExceeded < StandardError; end

  NUMBER_OF_PERMITTED_BOARDS = 1
  UNKNOWN_IMPORT_URL = 'http://unknown.git'

  cache_markdown_field :description, pipeline: :description

  delegate :feature_available?, :builds_enabled?, :wiki_enabled?,
           :merge_requests_enabled?, :issues_enabled?, to: :project_feature,
                                                       allow_nil: true

  default_value_for :archived, false
  default_value_for :visibility_level, gitlab_config_features.visibility_level
  default_value_for :container_registry_enabled, gitlab_config_features.container_registry
  default_value_for(:repository_storage) { current_application_settings.pick_repository_storage }
  default_value_for(:shared_runners_enabled) { current_application_settings.shared_runners_enabled }
  default_value_for :issues_enabled, gitlab_config_features.issues
  default_value_for :merge_requests_enabled, gitlab_config_features.merge_requests
  default_value_for :builds_enabled, gitlab_config_features.builds
  default_value_for :wiki_enabled, gitlab_config_features.wiki
  default_value_for :snippets_enabled, gitlab_config_features.snippets
  default_value_for :only_allow_merge_if_all_discussions_are_resolved, false

  after_create :ensure_dir_exist
  after_create :create_project_feature, unless: :project_feature
  after_save :ensure_dir_exist, if: :namespace_id_changed?

  # set last_activity_at to the same as created_at
  after_create :set_last_activity_at
  def set_last_activity_at
    update_column(:last_activity_at, self.created_at)
  end

  # update visibility_level of forks
  after_update :update_forks_visibility_level
  def update_forks_visibility_level
    return unless visibility_level < visibility_level_was

    forks.each do |forked_project|
      if forked_project.visibility_level > visibility_level
        forked_project.visibility_level = visibility_level
        forked_project.save!
      end
    end
  end

  ActsAsTaggableOn.strict_case_match = true
  acts_as_taggable_on :tags

  attr_accessor :new_default_branch
  attr_accessor :old_path_with_namespace

  alias_attribute :title, :name

  # Relations
  belongs_to :creator, class_name: 'User'
  belongs_to :group, -> { where(type: 'Group') }, foreign_key: 'namespace_id'
  belongs_to :namespace

  has_one :last_event, -> {order 'events.created_at DESC'}, class_name: 'Event'
  has_many :boards, before_add: :validate_board_limit, dependent: :destroy
  has_many :chat_services

  # Project services
  has_one :campfire_service, dependent: :destroy
  has_one :drone_ci_service, dependent: :destroy
  has_one :emails_on_push_service, dependent: :destroy
  has_one :builds_email_service, dependent: :destroy
  has_one :pipelines_email_service, dependent: :destroy
  has_one :irker_service, dependent: :destroy
  has_one :pivotaltracker_service, dependent: :destroy
  has_one :hipchat_service, dependent: :destroy
  has_one :flowdock_service, dependent: :destroy
  has_one :assembla_service, dependent: :destroy
  has_one :asana_service, dependent: :destroy
  has_one :gemnasium_service, dependent: :destroy
  has_one :mattermost_slash_commands_service, dependent: :destroy
  has_one :slack_service, dependent: :destroy
  has_one :buildkite_service, dependent: :destroy
  has_one :bamboo_service, dependent: :destroy
  has_one :teamcity_service, dependent: :destroy
  has_one :pushover_service, dependent: :destroy
  has_one :jira_service, dependent: :destroy
  has_one :redmine_service, dependent: :destroy
  has_one :custom_issue_tracker_service, dependent: :destroy
  has_one :bugzilla_service, dependent: :destroy
  has_one :gitlab_issue_tracker_service, dependent: :destroy, inverse_of: :project
  has_one :external_wiki_service, dependent: :destroy

  has_one  :forked_project_link,  dependent: :destroy, foreign_key: "forked_to_project_id"
  has_one  :forked_from_project,  through:   :forked_project_link

  has_many :forked_project_links, foreign_key: "forked_from_project_id"
  has_many :forks,                through:     :forked_project_links, source: :forked_to_project

  # Merge Requests for target project should be removed with it
  has_many :merge_requests,     dependent: :destroy, foreign_key: 'target_project_id'
  # Merge requests from source project should be kept when source project was removed
  has_many :fork_merge_requests, foreign_key: 'source_project_id', class_name: MergeRequest
  has_many :issues,             dependent: :destroy
  has_many :labels,             dependent: :destroy, class_name: 'ProjectLabel'
  has_many :services,           dependent: :destroy
  has_many :events,             dependent: :destroy
  has_many :milestones,         dependent: :destroy
  has_many :notes,              dependent: :destroy
  has_many :snippets,           dependent: :destroy, class_name: 'ProjectSnippet'
  has_many :hooks,              dependent: :destroy, class_name: 'ProjectHook'
  has_many :protected_branches, dependent: :destroy

  has_many :project_members, -> { where(requested_at: nil) }, dependent: :destroy, as: :source
  alias_method :members, :project_members
  has_many :users, through: :project_members

  has_many :requesters, -> { where.not(requested_at: nil) }, dependent: :destroy, as: :source, class_name: 'ProjectMember'

  has_many :deploy_keys_projects, dependent: :destroy
  has_many :deploy_keys, through: :deploy_keys_projects
  has_many :users_star_projects, dependent: :destroy
  has_many :starrers, through: :users_star_projects, source: :user
  has_many :releases, dependent: :destroy
  has_many :lfs_objects_projects, dependent: :destroy
  has_many :lfs_objects, through: :lfs_objects_projects
  has_many :project_group_links, dependent: :destroy
  has_many :invited_groups, through: :project_group_links, source: :group
  has_many :todos, dependent: :destroy
  has_many :notification_settings, dependent: :destroy, as: :source

  has_one :import_data, dependent: :destroy, class_name: "ProjectImportData"
  has_one :project_feature, dependent: :destroy

  has_many :commit_statuses, dependent: :destroy, foreign_key: :gl_project_id
  has_many :pipelines, dependent: :destroy, class_name: 'Ci::Pipeline', foreign_key: :gl_project_id
  has_many :builds, class_name: 'Ci::Build', foreign_key: :gl_project_id # the builds are created from the commit_statuses
  has_many :runner_projects, dependent: :destroy, class_name: 'Ci::RunnerProject', foreign_key: :gl_project_id
  has_many :runners, through: :runner_projects, source: :runner, class_name: 'Ci::Runner'
  has_many :variables, dependent: :destroy, class_name: 'Ci::Variable', foreign_key: :gl_project_id
  has_many :triggers, dependent: :destroy, class_name: 'Ci::Trigger', foreign_key: :gl_project_id
  has_many :environments, dependent: :destroy
  has_many :deployments, dependent: :destroy

  accepts_nested_attributes_for :variables, allow_destroy: true
  accepts_nested_attributes_for :project_feature

  delegate :name, to: :owner, allow_nil: true, prefix: true
  delegate :members, to: :team, prefix: true
  delegate :add_user, to: :team

  # Validations
  validates :creator, presence: true, on: :create
  validates :description, length: { maximum: 2000 }, allow_blank: true
  validates :name,
    presence: true,
    length: { within: 0..255 },
    format: { with: Gitlab::Regex.project_name_regex,
              message: Gitlab::Regex.project_name_regex_message }
  validates :path,
    presence: true,
    length: { within: 0..255 },
    format: { with: Gitlab::Regex.project_path_regex,
              message: Gitlab::Regex.project_path_regex_message }
  validates :namespace, presence: true
  validates_uniqueness_of :name, scope: :namespace_id
  validates_uniqueness_of :path, scope: :namespace_id
  validates :import_url, addressable_url: true, if: :external_import?
  validates :star_count, numericality: { greater_than_or_equal_to: 0 }
  validate :check_limit, on: :create
  validate :avatar_type,
    if: ->(project) { project.avatar.present? && project.avatar_changed? }
  validates :avatar, file_size: { maximum: 200.kilobytes.to_i }
  validate :visibility_level_allowed_by_group
  validate :visibility_level_allowed_as_fork
  validate :check_wiki_path_conflict
  validates :repository_storage,
    presence: true,
    inclusion: { in: ->(_object) { Gitlab.config.repositories.storages.keys } }

  add_authentication_token_field :runners_token
  before_save :ensure_runners_token

  mount_uploader :avatar, AvatarUploader

  # Scopes
  default_scope { where(pending_delete: false) }

  scope :sorted_by_activity, -> { reorder(last_activity_at: :desc) }
  scope :sorted_by_stars, -> { reorder('projects.star_count DESC') }

  scope :in_namespace, ->(namespace_ids) { where(namespace_id: namespace_ids) }
  scope :personal, ->(user) { where(namespace_id: user.namespace_id) }
  scope :joined, ->(user) { where('namespace_id != ?', user.namespace_id) }
  scope :visible_to_user, ->(user) { where(id: user.authorized_projects.select(:id).reorder(nil)) }
  scope :non_archived, -> { where(archived: false) }
  scope :for_milestones, ->(ids) { joins(:milestones).where('milestones.id' => ids).distinct }
  scope :with_push, -> { joins(:events).where('events.action = ?', Event::PUSHED) }

  scope :with_project_feature, -> { joins('LEFT JOIN project_features ON projects.id = project_features.project_id') }

  # "enabled" here means "not disabled". It includes private features!
  scope :with_feature_enabled, ->(feature) {
    access_level_attribute = ProjectFeature.access_level_attribute(feature)
    with_project_feature.where(project_features: { access_level_attribute => [nil, ProjectFeature::PRIVATE, ProjectFeature::ENABLED] })
  }

  # Picks a feature where the level is exactly that given.
  scope :with_feature_access_level, ->(feature, level) {
    access_level_attribute = ProjectFeature.access_level_attribute(feature)
    with_project_feature.where(project_features: { access_level_attribute => level })
  }

  scope :with_builds_enabled, -> { with_feature_enabled(:builds) }
  scope :with_issues_enabled, -> { with_feature_enabled(:issues) }

  # project features may be "disabled", "internal" or "enabled". If "internal",
  # they are only available to team members. This scope returns projects where
  # the feature is either enabled, or internal with permission for the user.
  def self.with_feature_available_for_user(feature, user)
    return with_feature_enabled(feature) if user.try(:admin?)

    unconditional = with_feature_access_level(feature, [nil, ProjectFeature::ENABLED])
    return unconditional if user.nil?

    conditional = with_feature_access_level(feature, ProjectFeature::PRIVATE)
    authorized = user.authorized_projects.merge(conditional.reorder(nil))

    union = Gitlab::SQL::Union.new([unconditional.select(:id), authorized.select(:id)])
    where(arel_table[:id].in(Arel::Nodes::SqlLiteral.new(union.to_sql)))
  end

  scope :active, -> { joins(:issues, :notes, :merge_requests).order('issues.created_at, notes.created_at, merge_requests.created_at DESC') }
  scope :abandoned, -> { where('projects.last_activity_at < ?', 6.months.ago) }

  scope :excluding_project, ->(project) { where.not(id: project) }

  state_machine :import_status, initial: :none do
    event :import_start do
      transition [:none, :finished] => :started
    end

    event :import_finish do
      transition started: :finished
    end

    event :import_fail do
      transition started: :failed
    end

    event :import_retry do
      transition failed: :started
    end

    state :started
    state :finished
    state :failed

    after_transition any => :finished, do: :reset_cache_and_import_attrs
  end

  class << self
    # Searches for a list of projects based on the query given in `query`.
    #
    # On PostgreSQL this method uses "ILIKE" to perform a case-insensitive
    # search. On MySQL a regular "LIKE" is used as it's already
    # case-insensitive.
    #
    # query - The search query as a String.
    def search(query)
      ptable  = arel_table
      ntable  = Namespace.arel_table
      pattern = "%#{query}%"

      projects = select(:id).where(
        ptable[:path].matches(pattern).
          or(ptable[:name].matches(pattern)).
          or(ptable[:description].matches(pattern))
      )

      # We explicitly remove any eager loading clauses as they're:
      #
      # 1. Not needed by this query
      # 2. Combined with .joins(:namespace) lead to all columns from the
      #    projects & namespaces tables being selected, leading to a SQL error
      #    due to the columns of all UNION'd queries no longer being the same.
      namespaces = select(:id).
        except(:includes).
        joins(:namespace).
        where(ntable[:name].matches(pattern))

      union = Gitlab::SQL::Union.new([projects, namespaces])

      where("projects.id IN (#{union.to_sql})")
    end

    def search_by_visibility(level)
      where(visibility_level: Gitlab::VisibilityLevel.const_get(level.upcase))
    end

    def search_by_title(query)
      pattern = "%#{query}%"
      table   = Project.arel_table

      non_archived.where(table[:name].matches(pattern))
    end

    # Finds a single project for the given path.
    #
    # path - The full project path (including namespace path).
    #
    # Returns a Project, or nil if no project could be found.
    def find_with_namespace(path)
      namespace_path, project_path = path.split('/', 2)

      return unless namespace_path && project_path

      namespace_path = connection.quote(namespace_path)
      project_path = connection.quote(project_path)

      # On MySQL we want to ensure the ORDER BY uses a case-sensitive match so
      # any literal matches come first, for this we have to use "BINARY".
      # Without this there's still no guarantee in what order MySQL will return
      # rows.
      binary = Gitlab::Database.mysql? ? 'BINARY' : ''

      order_sql = "(CASE WHEN #{binary} namespaces.path = #{namespace_path} " \
        "AND #{binary} projects.path = #{project_path} THEN 0 ELSE 1 END)"

      where_paths_in([path]).reorder(order_sql).take
    end

    # Builds a relation to find multiple projects by their full paths.
    #
    # Each path must be in the following format:
    #
    #     namespace_path/project_path
    #
    # For example:
    #
    #     gitlab-org/gitlab-ce
    #
    # Usage:
    #
    #     Project.where_paths_in(%w{gitlab-org/gitlab-ce gitlab-org/gitlab-ee})
    #
    # This would return the projects with the full paths matching the values
    # given.
    #
    # paths - An Array of full paths (namespace path + project path) for which
    #         to find the projects.
    #
    # Returns an ActiveRecord::Relation.
    def where_paths_in(paths)
      wheres = []
      cast_lower = Gitlab::Database.postgresql?

      paths.each do |path|
        namespace_path, project_path = path.split('/', 2)

        next unless namespace_path && project_path

        namespace_path = connection.quote(namespace_path)
        project_path = connection.quote(project_path)

        where = "(namespaces.path = #{namespace_path}
          AND projects.path = #{project_path})"

        if cast_lower
          where = "(
            #{where}
            OR (
              LOWER(namespaces.path) = LOWER(#{namespace_path})
              AND LOWER(projects.path) = LOWER(#{project_path})
            )
          )"
        end

        wheres << where
      end

      if wheres.empty?
        none
      else
        joins(:namespace).where(wheres.join(' OR '))
      end
    end

    def visibility_levels
      Gitlab::VisibilityLevel.options
    end

    def sort(method)
      if method == 'repository_size_desc'
        reorder(repository_size: :desc, id: :desc)
      else
        order_by(method)
      end
    end

    def reference_pattern
      name_pattern = Gitlab::Regex::NAMESPACE_REGEX_STR
      %r{(?<project>#{name_pattern}/#{name_pattern})}
    end

    def trending
      joins('INNER JOIN trending_projects ON projects.id = trending_projects.project_id').
        reorder('trending_projects.id ASC')
    end

    def cached_count
      Rails.cache.fetch('total_project_count', expires_in: 5.minutes) do
        Project.count
      end
    end

    def group_ids
      joins(:namespace).where(namespaces: { type: 'Group' }).select(:namespace_id)
    end
  end

  def lfs_enabled?
    return namespace.lfs_enabled? if self[:lfs_enabled].nil?

    self[:lfs_enabled] && Gitlab.config.lfs.enabled
  end

  def repository_storage_path
    Gitlab.config.repositories.storages[repository_storage]
  end

  def team
    @team ||= ProjectTeam.new(self)
  end

  def repository
    @repository ||= Repository.new(path_with_namespace, self)
  end

  def container_registry_path_with_namespace
    path_with_namespace.downcase
  end

  def container_registry_repository
    return unless Gitlab.config.registry.enabled

    @container_registry_repository ||= begin
      token = Auth::ContainerRegistryAuthenticationService.full_access_token(container_registry_path_with_namespace)
      url = Gitlab.config.registry.api_url
      host_port = Gitlab.config.registry.host_port
      registry = ContainerRegistry::Registry.new(url, token: token, path: host_port)
      registry.repository(container_registry_path_with_namespace)
    end
  end

  def container_registry_repository_url
    if Gitlab.config.registry.enabled
      "#{Gitlab.config.registry.host_port}/#{container_registry_path_with_namespace}"
    end
  end

  def has_container_registry_tags?
    return unless container_registry_repository

    container_registry_repository.tags.any?
  end

  def commit(ref = 'HEAD')
    repository.commit(ref)
  end

  # ref can't be HEAD, can only be branch/tag name or SHA
  def latest_successful_builds_for(ref = default_branch)
    latest_pipeline = pipelines.latest_successful_for(ref)

    if latest_pipeline
      latest_pipeline.builds.latest.with_artifacts
    else
      builds.none
    end
  end

  def merge_base_commit(first_commit_id, second_commit_id)
    sha = repository.merge_base(first_commit_id, second_commit_id)
    repository.commit(sha) if sha
  end

  def saved?
    id && persisted?
  end

  def add_import_job
    if forked?
      job_id = RepositoryForkWorker.perform_async(id, forked_from_project.repository_storage_path,
                                                  forked_from_project.path_with_namespace,
                                                  self.namespace.path)
    else
      job_id = RepositoryImportWorker.perform_async(self.id)
    end

    if job_id
      Rails.logger.info "Import job started for #{path_with_namespace} with job ID #{job_id}"
    else
      Rails.logger.error "Import job failed to start for #{path_with_namespace}"
    end
  end

  def reset_cache_and_import_attrs
    ProjectCacheWorker.perform_async(self.id)

    self.import_data.destroy if self.import_data
  end

  def import_url=(value)
    return super(value) unless Gitlab::UrlSanitizer.valid?(value)

    import_url = Gitlab::UrlSanitizer.new(value)
    super(import_url.sanitized_url)
    create_or_update_import_data(credentials: import_url.credentials)
  end

  def import_url
    if import_data && super.present?
      import_url = Gitlab::UrlSanitizer.new(super, credentials: import_data.credentials)
      import_url.full_url
    else
      super
    end
  end

  def valid_import_url?
    valid? || errors.messages[:import_url].nil?
  end

  def create_or_update_import_data(data: nil, credentials: nil)
    return unless import_url.present? && valid_import_url?

    project_import_data = import_data || build_import_data
    if data
      project_import_data.data ||= {}
      project_import_data.data = project_import_data.data.merge(data)
    end
    if credentials
      project_import_data.credentials ||= {}
      project_import_data.credentials = project_import_data.credentials.merge(credentials)
    end

    project_import_data.save
  end

  def import?
    external_import? || forked? || gitlab_project_import?
  end

  def no_import?
    import_status == 'none'
  end

  def external_import?
    import_url.present?
  end

  def imported?
    import_finished?
  end

  def import_in_progress?
    import? && import_status == 'started'
  end

  def import_failed?
    import_status == 'failed'
  end

  def import_finished?
    import_status == 'finished'
  end

  def safe_import_url
    Gitlab::UrlSanitizer.new(import_url).masked_url
  end

  def gitlab_project_import?
    import_type == 'gitlab_project'
  end

  def check_limit
    unless creator.can_create_project? or namespace.kind == 'group'
      projects_limit = creator.projects_limit

      if projects_limit == 0
        self.errors.add(:limit_reached, "Personal project creation is not allowed. Please contact your administrator with questions")
      else
        self.errors.add(:limit_reached, "Your project limit is #{projects_limit} projects! Please contact your administrator to increase it")
      end
    end
  rescue
    self.errors.add(:base, "Can't check your ability to create project")
  end

  def visibility_level_allowed_by_group
    return if visibility_level_allowed_by_group?

    level_name = Gitlab::VisibilityLevel.level_name(self.visibility_level).downcase
    group_level_name = Gitlab::VisibilityLevel.level_name(self.group.visibility_level).downcase
    self.errors.add(:visibility_level, "#{level_name} is not allowed in a #{group_level_name} group.")
  end

  def visibility_level_allowed_as_fork
    return if visibility_level_allowed_as_fork?

    level_name = Gitlab::VisibilityLevel.level_name(self.visibility_level).downcase
    self.errors.add(:visibility_level, "#{level_name} is not allowed since the fork source project has lower visibility.")
  end

  def check_wiki_path_conflict
    return if path.blank?

    path_to_check = path.ends_with?('.wiki') ? path.chomp('.wiki') : "#{path}.wiki"

    if Project.where(namespace_id: namespace_id, path: path_to_check).exists?
      errors.add(:name, 'has already been taken')
    end
  end

  def to_param
    if persisted? && errors.include?(:path)
      path_was
    else
      path
    end
  end

  def to_reference(_from_project = nil)
    path_with_namespace
  end

  def web_url
    Gitlab::Routing.url_helpers.namespace_project_url(self.namespace, self)
  end

  def web_url_without_protocol
    web_url.split('://')[1]
  end

  def new_issue_address(author)
    return unless Gitlab::IncomingEmail.supports_issue_creation? && author

    author.ensure_incoming_email_token!

    Gitlab::IncomingEmail.reply_address(
      "#{path_with_namespace}+#{author.incoming_email_token}")
  end

  def build_commit_note(commit)
    notes.new(commit_id: commit.id, noteable_type: 'Commit')
  end

  def last_activity
    last_event
  end

  def last_activity_date
    last_activity_at || updated_at
  end

  def project_id
    self.id
  end

  def get_issue(issue_id, current_user)
    if default_issues_tracker?
      IssuesFinder.new(current_user, project_id: id).find_by(iid: issue_id)
    else
      ExternalIssue.new(issue_id, self)
    end
  end

  def issue_exists?(issue_id)
    get_issue(issue_id)
  end

  def default_issue_tracker
    gitlab_issue_tracker_service || create_gitlab_issue_tracker_service
  end

  def issues_tracker
    if external_issue_tracker
      external_issue_tracker
    else
      default_issue_tracker
    end
  end

  def issue_reference_pattern
    issues_tracker.reference_pattern
  end

  def default_issues_tracker?
    !external_issue_tracker
  end

  def external_issue_tracker
    if has_external_issue_tracker.nil? # To populate existing projects
      cache_has_external_issue_tracker
    end

    if has_external_issue_tracker?
      return @external_issue_tracker if defined?(@external_issue_tracker)

      @external_issue_tracker = services.external_issue_trackers.first
    else
      nil
    end
  end

  def cache_has_external_issue_tracker
    update_column(:has_external_issue_tracker, services.external_issue_trackers.any?)
  end

  def has_wiki?
    wiki_enabled? || has_external_wiki?
  end

  def external_wiki
    if has_external_wiki.nil?
      cache_has_external_wiki # Populate
    end

    if has_external_wiki
      @external_wiki ||= services.external_wikis.first
    else
      nil
    end
  end

  def cache_has_external_wiki
    update_column(:has_external_wiki, services.external_wikis.any?)
  end

  def find_or_initialize_services
    services_templates = Service.where(template: true)

    Service.available_services_names.map do |service_name|
      service = find_service(services, service_name)

      if service
        service
      else
        # We should check if template for the service exists
        template = find_service(services_templates, service_name)

        if template.nil?
          # If no template, we should create an instance. Ex `build_gitlab_ci_service`
          public_send("build_#{service_name}_service")
        else
          Service.build_from_template(id, template)
        end
      end
    end
  end

  def find_or_initialize_service(name)
    find_or_initialize_services.find { |service| service.to_param == name }
  end

  def create_labels
    Label.templates.each do |label|
      params = label.attributes.except('id', 'template', 'created_at', 'updated_at')
      Labels::FindOrCreateService.new(nil, self, params).execute(skip_authorization: true)
    end
  end

  def find_service(list, name)
    list.find { |service| service.to_param == name }
  end

  def ci_services
    services.where(category: :ci)
  end

  def ci_service
    @ci_service ||= ci_services.reorder(nil).find_by(active: true)
  end

  def jira_tracker?
    issues_tracker.to_param == 'jira'
  end

  def avatar_type
    unless self.avatar.image?
      self.errors.add :avatar, 'only images allowed'
    end
  end

  def avatar_in_git
    repository.avatar
  end

  def avatar_url
    if self[:avatar].present?
      [gitlab_config.url, avatar.url].join
    elsif avatar_in_git
      Gitlab::Routing.url_helpers.namespace_project_avatar_url(namespace, self)
    end
  end

  # For compatibility with old code
  def code
    path
  end

  def items_for(entity)
    case entity
    when 'issue' then
      issues
    when 'merge_request' then
      merge_requests
    end
  end

  def send_move_instructions(old_path_with_namespace)
    # New project path needs to be committed to the DB or notification will
    # retrieve stale information
    run_after_commit { NotificationService.new.project_was_moved(self, old_path_with_namespace) }
  end

  def owner
    if group
      group
    else
      namespace.try(:owner)
    end
  end

  def name_with_namespace
    @name_with_namespace ||= begin
                               if namespace
                                 namespace.human_name + ' / ' + name
                               else
                                 name
                               end
                             end
  end
  alias_method :human_name, :name_with_namespace

  def path_with_namespace
    if namespace
      namespace.path + '/' + path
    else
      path
    end
  end

  def execute_hooks(data, hooks_scope = :push_hooks)
    hooks.send(hooks_scope).each do |hook|
      hook.async_execute(data, hooks_scope.to_s)
    end
  end

  def execute_services(data, hooks_scope = :push_hooks)
    # Call only service hooks that are active for this scope
    services.send(hooks_scope).each do |service|
      service.async_execute(data)
    end
  end

  def valid_repo?
    repository.exists?
  rescue
    errors.add(:path, 'Invalid repository path')
    false
  end

  def empty_repo?
    repository.empty_repo?
  end

  def repo
    repository.raw
  end

  def url_to_repo
    gitlab_shell.url_to_repo(path_with_namespace)
  end

  def namespace_dir
    namespace.try(:path) || ''
  end

  def repo_exists?
    @repo_exists ||= repository.exists?
  rescue
    @repo_exists = false
  end

  # Branches that are not _exactly_ matched by a protected branch.
  def open_branches
    exact_protected_branch_names = protected_branches.reject(&:wildcard?).map(&:name)
    branch_names = repository.branches.map(&:name)
    non_open_branch_names = Set.new(exact_protected_branch_names).intersection(Set.new(branch_names))
    repository.branches.reject { |branch| non_open_branch_names.include? branch.name }
  end

  def root_ref?(branch)
    repository.root_ref == branch
  end

  def ssh_url_to_repo
    url_to_repo
  end

  def http_url_to_repo
    "#{web_url}.git"
  end

  # Check if current branch name is marked as protected in the system
  def protected_branch?(branch_name)
    return true if empty_repo? && default_branch_protected?

    @protected_branches ||= self.protected_branches.to_a
    ProtectedBranch.matching(branch_name, protected_branches: @protected_branches).present?
  end

  def user_can_push_to_empty_repo?(user)
    !default_branch_protected? || team.max_member_access(user.id) > Gitlab::Access::DEVELOPER
  end

  def forked?
    !(forked_project_link.nil? || forked_project_link.forked_from_project.nil?)
  end

  def personal?
    !group
  end

  def rename_repo
    path_was = previous_changes['path'].first
    old_path_with_namespace = File.join(namespace_dir, path_was)
    new_path_with_namespace = File.join(namespace_dir, path)

    Rails.logger.error "Attempting to rename #{old_path_with_namespace} -> #{new_path_with_namespace}"

    expire_caches_before_rename(old_path_with_namespace)

    if has_container_registry_tags?
      Rails.logger.error "Project #{old_path_with_namespace} cannot be renamed because container registry tags are present"

      # we currently doesn't support renaming repository if it contains tags in container registry
      raise Exception.new('Project cannot be renamed, because tags are present in its container registry')
    end

    if gitlab_shell.mv_repository(repository_storage_path, old_path_with_namespace, new_path_with_namespace)
      # If repository moved successfully we need to send update instructions to users.
      # However we cannot allow rollback since we moved repository
      # So we basically we mute exceptions in next actions
      begin
        gitlab_shell.mv_repository(repository_storage_path, "#{old_path_with_namespace}.wiki", "#{new_path_with_namespace}.wiki")
        send_move_instructions(old_path_with_namespace)

        @old_path_with_namespace = old_path_with_namespace

        SystemHooksService.new.execute_hooks_for(self, :rename)

        @repository = nil
      rescue => e
        Rails.logger.error "Exception renaming #{old_path_with_namespace} -> #{new_path_with_namespace}: #{e}"
        # Returning false does not rollback after_* transaction but gives
        # us information about failing some of tasks
        false
      end
    else
      Rails.logger.error "Repository could not be renamed: #{old_path_with_namespace} -> #{new_path_with_namespace}"

      # if we cannot move namespace directory we should rollback
      # db changes in order to prevent out of sync between db and fs
      raise Exception.new('repository cannot be renamed')
    end

    Gitlab::AppLogger.info "Project was renamed: #{old_path_with_namespace} -> #{new_path_with_namespace}"

    Gitlab::UploadsTransfer.new.rename_project(path_was, path, namespace.path)
  end

  # Expires various caches before a project is renamed.
  def expire_caches_before_rename(old_path)
    repo = Repository.new(old_path, self)
    wiki = Repository.new("#{old_path}.wiki", self)

    if repo.exists?
      repo.before_delete
    end

    if wiki.exists?
      wiki.before_delete
    end
  end

  def hook_attrs(backward: true)
    attrs = {
      name: name,
      description: description,
      web_url: web_url,
      avatar_url: avatar_url,
      git_ssh_url: ssh_url_to_repo,
      git_http_url: http_url_to_repo,
      namespace: namespace.name,
      visibility_level: visibility_level,
      path_with_namespace: path_with_namespace,
      default_branch: default_branch,
    }

    # Backward compatibility
    if backward
      attrs.merge!({
                    homepage: web_url,
                    url: url_to_repo,
                    ssh_url: ssh_url_to_repo,
                    http_url: http_url_to_repo
                  })
    end

    attrs
  end

  def project_member(user)
    project_members.find_by(user_id: user)
  end

  def default_branch
    @default_branch ||= repository.root_ref if repository.exists?
  end

  def reload_default_branch
    @default_branch = nil
    default_branch
  end

  def visibility_level_field
    visibility_level
  end

  def archive!
    update_attribute(:archived, true)
  end

  def unarchive!
    update_attribute(:archived, false)
  end

  def change_head(branch)
    repository.before_change_head
    repository.rugged.references.create('HEAD',
                                        "refs/heads/#{branch}",
                                        force: true)
    repository.copy_gitattributes(branch)
    repository.expire_avatar_cache
    reload_default_branch
  end

  def forked_from?(project)
    forked? && project == forked_from_project
  end

  def update_repository_size
    update_attribute(:repository_size, repository.size)
  end

  def update_commit_count
    update_attribute(:commit_count, repository.commit_count)
  end

  def forks_count
    forks.count
  end

  def origin_merge_requests
    merge_requests.where(source_project_id: self.id)
  end

  def create_repository
    # Forked import is handled asynchronously
    unless forked?
      if gitlab_shell.add_repository(repository_storage_path, path_with_namespace)
        repository.after_create
        true
      else
        errors.add(:base, 'Failed to create repository via gitlab-shell')
        false
      end
    end
  end

  def repository_exists?
    !!repository.exists?
  end

  def create_wiki
    ProjectWiki.new(self, self.owner).wiki
    true
  rescue ProjectWiki::CouldNotCreateWikiError
    errors.add(:base, 'Failed create wiki')
    false
  end

  def jira_tracker_active?
    jira_tracker? && jira_service.active
  end

  def allowed_to_share_with_group?
    !namespace.share_with_group_lock
  end

  def pipeline_for(ref, sha = nil)
    sha ||= commit(ref).try(:sha)

    return unless sha

    pipelines.order(id: :desc).find_by(sha: sha, ref: ref)
  end

  def ensure_pipeline(ref, sha, current_user = nil)
    pipeline_for(ref, sha) ||
      pipelines.create(sha: sha, ref: ref, user: current_user)
  end

  def enable_ci
    project_feature.update_attribute(:builds_access_level, ProjectFeature::ENABLED)
  end

  def any_runners?(&block)
    if runners.active.any?(&block)
      return true
    end

    shared_runners_enabled? && Ci::Runner.shared.active.any?(&block)
  end

  def valid_runners_token?(token)
    self.runners_token && ActiveSupport::SecurityUtils.variable_size_secure_compare(token, self.runners_token)
  end

  def build_coverage_enabled?
    build_coverage_regex.present?
  end

  def build_timeout_in_minutes
    build_timeout / 60
  end

  def build_timeout_in_minutes=(value)
    self.build_timeout = value.to_i * 60
  end

  def open_issues_count
    issues.opened.count
  end

  def visibility_level_allowed_as_fork?(level = self.visibility_level)
    return true unless forked?

    # self.forked_from_project will be nil before the project is saved, so
    # we need to go through the relation
    original_project = forked_project_link.forked_from_project
    return true unless original_project

    level <= original_project.visibility_level
  end

  def visibility_level_allowed_by_group?(level = self.visibility_level)
    return true unless group

    level <= group.visibility_level
  end

  def visibility_level_allowed?(level = self.visibility_level)
    visibility_level_allowed_as_fork?(level) && visibility_level_allowed_by_group?(level)
  end

  def runners_token
    ensure_runners_token!
  end

  def wiki
    @wiki ||= ProjectWiki.new(self, self.owner)
  end

  def running_or_pending_build_count(force: false)
    Rails.cache.fetch(['projects', id, 'running_or_pending_build_count'], force: force) do
      builds.running_or_pending.count(:all)
    end
  end

  def mark_import_as_failed(error_message)
    original_errors = errors.dup
    sanitized_message = Gitlab::UrlSanitizer.sanitize(error_message)

    import_fail
    update_column(:import_error, sanitized_message)
  rescue ActiveRecord::ActiveRecordError => e
    Rails.logger.error("Error setting import status to failed: #{e.message}. Original error: #{sanitized_message}")
  ensure
    @errors = original_errors
  end

  def add_export_job(current_user:)
    job_id = ProjectExportWorker.perform_async(current_user.id, self.id)

    if job_id
      Rails.logger.info "Export job started for project ID #{self.id} with job ID #{job_id}"
    else
      Rails.logger.error "Export job failed to start for project ID #{self.id}"
    end
  end

  def export_path
    File.join(Gitlab::ImportExport.storage_path, path_with_namespace)
  end

  def export_project_path
    Dir.glob("#{export_path}/*export.tar.gz").max_by { |f| File.ctime(f) }
  end

  def remove_exports
    _, status = Gitlab::Popen.popen(%W(find #{export_path} -not -path #{export_path} -delete))
    status.zero?
  end

  def ensure_dir_exist
    gitlab_shell.add_namespace(repository_storage_path, namespace.path)
  end

  def predefined_variables
    [
      { key: 'CI_PROJECT_ID', value: id.to_s, public: true },
      { key: 'CI_PROJECT_NAME', value: path, public: true },
      { key: 'CI_PROJECT_PATH', value: path_with_namespace, public: true },
      { key: 'CI_PROJECT_NAMESPACE', value: namespace.path, public: true },
      { key: 'CI_PROJECT_URL', value: web_url, public: true }
    ]
  end

  def container_registry_variables
    return [] unless Gitlab.config.registry.enabled

    variables = [
      { key: 'CI_REGISTRY', value: Gitlab.config.registry.host_port, public: true }
    ]

    if container_registry_enabled?
      variables << { key: 'CI_REGISTRY_IMAGE', value: container_registry_repository_url, public: true }
    end

    variables
  end

  def secret_variables
    variables.map do |variable|
      { key: variable.key, value: variable.value, public: false }
    end
  end

  # Checks if `user` is authorized for this project, with at least the
  # `min_access_level` (if given).
  def authorized_for_user?(user, min_access_level = nil)
    return false unless user

    user.authorized_project?(self, min_access_level)
  end

  def append_or_update_attribute(name, value)
    old_values = public_send(name.to_s)

    if Project.reflect_on_association(name).try(:macro) == :has_many && old_values.any?
      update_attribute(name, old_values + value)
    else
      update_attribute(name, value)
    end
  end

  def pushes_since_gc
    Gitlab::Redis.with { |redis| redis.get(pushes_since_gc_redis_key).to_i }
  end

  def increment_pushes_since_gc
    Gitlab::Redis.with { |redis| redis.incr(pushes_since_gc_redis_key) }
  end

  def reset_pushes_since_gc
    Gitlab::Redis.with { |redis| redis.del(pushes_since_gc_redis_key) }
  end

  def environments_for(ref, commit: nil, with_tags: false)
    deployments_query = with_tags ? 'ref = ? OR tag IS TRUE' : 'ref = ?'

    environment_ids = deployments
      .where(deployments_query, ref.to_s)
      .group(:environment_id)
      .select(:environment_id)

    environments_found = environments.available
      .where(id: environment_ids).to_a

    return environments_found unless commit

    environments_found.select do |environment|
      environment.includes_commit?(commit)
    end
  end

  def environments_recently_updated_on_branch(branch)
    environments_for(branch).select do |environment|
      environment.recently_updated_on_branch?(branch)
    end
  end

  private

  def pushes_since_gc_redis_key
    "projects/#{id}/pushes_since_gc"
  end

  def default_branch_protected?
    current_application_settings.default_branch_protection == Gitlab::Access::PROTECTION_FULL ||
      current_application_settings.default_branch_protection == Gitlab::Access::PROTECTION_DEV_CAN_MERGE
  end

  # Similar to the normal callbacks that hook into the life cycle of an
  # Active Record object, you can also define callbacks that get triggered
  # when you add an object to an association collection. If any of these
  # callbacks throw an exception, the object will not be added to the
  # collection. Before you add a new board to the boards collection if you
  # already have 1, 2, or n it will fail, but it if you have 0 that is lower
  # than the number of permitted boards per project it won't fail.
  def validate_board_limit(board)
    raise BoardLimitExceeded, 'Number of permitted boards exceeded' if boards.size >= NUMBER_OF_PERMITTED_BOARDS
  end
end
