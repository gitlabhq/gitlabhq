# To add new service you should build a class inherited from Service
# and implement a set of methods
class Service < ActiveRecord::Base
  include Sortable
  serialize :properties, JSON

  default_value_for :active, false
  default_value_for :push_events, true
  default_value_for :issues_events, true
  default_value_for :merge_requests_events, true
  default_value_for :tag_push_events, true
  default_value_for :note_events, true
  default_value_for :build_events, true
  default_value_for :wiki_page_events, true

  after_initialize :initialize_properties

  after_commit :reset_updated_properties
  after_commit :cache_project_has_external_issue_tracker

  belongs_to :project, inverse_of: :services
  has_one :service_hook

  validates :project_id, presence: true, unless: Proc.new { |service| service.template? }

  scope :visible, -> { where.not(type: ['GitlabIssueTrackerService', 'GitlabCiService']) }
  scope :issue_trackers, -> { where(category: 'issue_tracker') }
  scope :active, -> { where(active: true) }
  scope :without_defaults, -> { where(default: false) }

  scope :push_hooks, -> { where(push_events: true, active: true) }
  scope :tag_push_hooks, -> { where(tag_push_events: true, active: true) }
  scope :issue_hooks, -> { where(issues_events: true, active: true) }
  scope :merge_request_hooks, -> { where(merge_requests_events: true, active: true) }
  scope :note_hooks, -> { where(note_events: true, active: true) }
  scope :build_hooks, -> { where(build_events: true, active: true) }
  scope :wiki_page_hooks, -> { where(wiki_page_events: true, active: true) }
  scope :external_issue_trackers, -> { issue_trackers.active.without_defaults }

  default_value_for :category, 'common'

  def activated?
    active
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
  end

  def fields
    # implement inside child
    []
  end

  def test_data(project, user)
    Gitlab::PushDataBuilder.build_sample(project, user)
  end

  def supported_events
    %w(push tag_push issue merge_request wiki_page)
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
    !project.empty_repo?
  end

  # reason why service cannot be tested
  def disabled_title
    "Please setup a project repository."
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

    Sidekiq::Client.enqueue(ProjectServiceWorker, id, data)
  end

  def issue_tracker?
    self.category == :issue_tracker
  end

  def self.available_services_names
    %w(
      asana
      assembla
      bamboo
      buildkite
      builds_email
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
      jenkins
      jenkins_deprecated
      jira
      pivotaltracker
      pushover
      redmine
      slack
      teamcity
    )
  end

  def self.create_from_template(project_id, template)
    service = template.dup
    service.template = false
    service.project_id = project_id
    service if service.save
  end

  private

  def cache_project_has_external_issue_tracker
    if project && !project.destroyed?
      project.cache_has_external_issue_tracker
    end
  end
end
