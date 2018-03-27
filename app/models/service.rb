# To add new service you should build a class inherited from Service
# and implement a set of methods
class Service < ActiveRecord::Base
  include Sortable
  include Importable

  serialize :properties, JSON # rubocop:disable Cop/ActiveRecordSerialize

  default_value_for :active, false
  default_value_for :push_events, true
  default_value_for :issues_events, true
  default_value_for :confidential_issues_events, true
  default_value_for :commit_events, true
  default_value_for :merge_requests_events, true
  default_value_for :tag_push_events, true
  default_value_for :note_events, true
  default_value_for :job_events, true
  default_value_for :pipeline_events, true
  default_value_for :wiki_page_events, true

  after_initialize :initialize_properties

  after_commit :reset_updated_properties
  after_commit :cache_project_has_external_issue_tracker
  after_commit :cache_project_has_external_wiki

  belongs_to :project, inverse_of: :services
  has_one :service_hook

  validates :project_id, presence: true, unless: proc { |service| service.template? }
  validates :type, presence: true

  scope :visible, -> { where.not(type: 'GitlabIssueTrackerService') }
  scope :issue_trackers, -> { where(category: 'issue_tracker') }
  scope :external_wikis, -> { where(type: 'ExternalWikiService').active }
  scope :active, -> { where(active: true) }
  scope :without_defaults, -> { where(default: false) }

  scope :push_hooks, -> { where(push_events: true, active: true) }
  scope :tag_push_hooks, -> { where(tag_push_events: true, active: true) }
  scope :issue_hooks, -> { where(issues_events: true, active: true) }
  scope :confidential_issue_hooks, -> { where(confidential_issues_events: true, active: true) }
  scope :merge_request_hooks, -> { where(merge_requests_events: true, active: true) }
  scope :note_hooks, -> { where(note_events: true, active: true) }
  scope :job_hooks, -> { where(job_events: true, active: true) }
  scope :pipeline_hooks, -> { where(pipeline_events: true, active: true) }
  scope :wiki_page_hooks, -> { where(wiki_page_events: true, active: true) }
  scope :external_issue_trackers, -> { issue_trackers.active.without_defaults }
  scope :deployment, -> { where(category: 'deployment') }

  default_value_for :category, 'common'

  def activated?
    active
  end

  def show_active_box?
    true
  end

  def editable?
    true
  end

  def template?
    template
  end

  def category
    read_attribute(:category).to_sym
  end

  def initialize_properties
    self.properties = {} if properties.nil?
  end

  def title
    # implement inside child
  end

  def description
    # implement inside child
  end

  def help
    # implement inside child
  end

  def to_param
    # implement inside child
    self.class.to_param
  end

  def self.to_param
    raise NotImplementedError
  end

  def fields
    # implement inside child
    []
  end

  def test_data(project, user)
    Gitlab::DataBuilder::Push.build_sample(project, user)
  end

  def event_channel_names
    []
  end

  def event_names
    self.class.event_names
  end

  def self.event_names
    self.supported_events.map { |event| "#{event}_events" }
  end

  def event_field(event)
    nil
  end

  def api_field_names
    fields.map { |field| field[:name] }
      .reject { |field_name| field_name =~ /(password|token|key)/ }
  end

  def global_fields
    fields
  end

  def configurable_events
    events = self.class.supported_events

    # No need to disable individual triggers when there is only one
    if events.count == 1
      []
    else
      events
    end
  end

  def supported_events
    self.class.supported_events
  end

  def self.supported_events
    %w(push tag_push issue confidential_issue merge_request wiki_page)
  end

  def execute(data)
    # implement inside child
  end

  def test(data)
    # default implementation
    result = execute(data)
    { success: result.present?, result: result }
  end

  def can_test?
    true
  end

  # Provide convenient accessor methods
  # for each serialized property.
  # Also keep track of updated properties in a similar way as ActiveModel::Dirty
  def self.prop_accessor(*args)
    args.each do |arg|
      class_eval %{
        def #{arg}
          properties['#{arg}']
        end

        def #{arg}=(value)
          self.properties ||= {}
          updated_properties['#{arg}'] = #{arg} unless #{arg}_changed?
          self.properties['#{arg}'] = value
        end

        def #{arg}_changed?
          #{arg}_touched? && #{arg} != #{arg}_was
        end

        def #{arg}_touched?
          updated_properties.include?('#{arg}')
        end

        def #{arg}_was
          updated_properties['#{arg}']
        end
      }
    end
  end

  # Provide convenient boolean accessor methods
  # for each serialized property.
  # Also keep track of updated properties in a similar way as ActiveModel::Dirty
  def self.boolean_accessor(*args)
    self.prop_accessor(*args)

    args.each do |arg|
      class_eval %{
        def #{arg}?
          ActiveRecord::ConnectionAdapters::Column::TRUE_VALUES.include?(#{arg})
        end
      }
    end
  end

  # Returns a hash of the properties that have been assigned a new value since last save,
  # indicating their original values (attr => original value).
  # ActiveRecord does not provide a mechanism to track changes in serialized keys,
  # so we need a specific implementation for service properties.
  # This allows to track changes to properties set with the accessor methods,
  # but not direct manipulation of properties hash.
  def updated_properties
    @updated_properties ||= ActiveSupport::HashWithIndifferentAccess.new
  end

  def reset_updated_properties
    @updated_properties = nil
  end

  def async_execute(data)
    return unless supported_events.include?(data[:object_kind])

    ProjectServiceWorker.perform_async(id, data)
  end

  def issue_tracker?
    self.category == :issue_tracker
  end

  def self.available_services_names
    service_names = %w[
      asana
      assembla
      bamboo
      buildkite
      bugzilla
      campfire
      custom_issue_tracker
      drone_ci
      emails_on_push
      external_wiki
      flowdock
      gemnasium
      hipchat
      irker
      jira
      kubernetes
      mattermost_slash_commands
      mattermost
      packagist
      pipelines_email
      pivotaltracker
      prometheus
      pushover
      redmine
      slack_slash_commands
      slack
      teamcity
      microsoft_teams
    ]

    if Rails.env.development?
      service_names += %w[mock_ci mock_deployment mock_monitoring]
    end

    service_names.sort_by(&:downcase)
  end

  def self.build_from_template(project_id, template)
    service = template.dup
    service.template = false
    service.project_id = project_id
    service
  end

  def deprecated?
    false
  end

  def deprecation_message
    nil
  end

  def self.find_by_template
    find_by(template: true)
  end

  private

  def cache_project_has_external_issue_tracker
    if project && !project.destroyed?
      project.cache_has_external_issue_tracker
    end
  end

  def cache_project_has_external_wiki
    if project && !project.destroyed?
      project.cache_has_external_wiki
    end
  end

  def self.event_description(event)
    case event
    when "push", "push_events"
      "Event will be triggered by a push to the repository"
    when "tag_push", "tag_push_events"
      "Event will be triggered when a new tag is pushed to the repository"
    when "note", "note_events"
      "Event will be triggered when someone adds a comment"
    when "issue", "issue_events"
      "Event will be triggered when an issue is created/updated/closed"
    when "confidential_issue", "confidential_issue_events"
      "Event will be triggered when a confidential issue is created/updated/closed"
    when "merge_request", "merge_request_events"
      "Event will be triggered when a merge request is created/updated/merged"
    when "pipeline", "pipeline_events"
      "Event will be triggered when a pipeline status changes"
    when "wiki_page", "wiki_page_events"
      "Event will be triggered when a wiki page is created/updated"
    when "commit", "commit_events"
      "Event will be triggered when a commit is created/updated"
    end
  end

  def valid_recipients?
    activated? && !importing?
  end
end
