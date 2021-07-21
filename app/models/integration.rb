# frozen_string_literal: true

# To add new integration you should build a class inherited from Integration
# and implement a set of methods
class Integration < ApplicationRecord
  include Sortable
  include Importable
  include ProjectServicesLoggable
  include Integrations::HasDataFields
  include FromUnion
  include EachBatch

  INTEGRATION_NAMES = %w[
    asana assembla bamboo bugzilla buildkite campfire confluence custom_issue_tracker datadog discord
    drone_ci emails_on_push ewm external_wiki flowdock hangouts_chat irker jira
    mattermost mattermost_slash_commands microsoft_teams packagist pipelines_email
    pivotaltracker prometheus pushover redmine slack slack_slash_commands teamcity unify_circuit webex_teams youtrack
  ].freeze

  PROJECT_SPECIFIC_INTEGRATION_NAMES = %w[
    jenkins
  ].freeze

  # Fake integrations to help with local development.
  DEV_INTEGRATION_NAMES = %w[
    mock_ci mock_monitoring
  ].freeze

  # Base classes which aren't actual integrations.
  BASE_CLASSES = %w[
    Integrations::BaseChatNotification
    Integrations::BaseCi
    Integrations::BaseIssueTracker
    Integrations::BaseMonitoring
    Integrations::BaseSlashCommands
  ].freeze

  serialize :properties, JSON # rubocop:disable Cop/ActiveRecordSerialize

  attribute :type, Gitlab::Integrations::StiType.new

  default_value_for :active, false
  default_value_for :alert_events, true
  default_value_for :category, 'common'
  default_value_for :commit_events, true
  default_value_for :confidential_issues_events, true
  default_value_for :confidential_note_events, true
  default_value_for :issues_events, true
  default_value_for :job_events, true
  default_value_for :merge_requests_events, true
  default_value_for :note_events, true
  default_value_for :pipeline_events, true
  default_value_for :push_events, true
  default_value_for :tag_push_events, true
  default_value_for :wiki_page_events, true

  after_initialize :initialize_properties

  after_commit :reset_updated_properties

  belongs_to :project, inverse_of: :integrations
  belongs_to :group, inverse_of: :integrations
  has_one :service_hook, inverse_of: :integration, foreign_key: :service_id

  validates :project_id, presence: true, unless: -> { instance_level? || group_level? }
  validates :group_id, presence: true, unless: -> { instance_level? || project_level? }
  validates :project_id, :group_id, absence: true, if: -> { instance_level? }
  validates :type, presence: true, exclusion: BASE_CLASSES
  validates :type, uniqueness: { scope: :instance }, if: :instance_level?
  validates :type, uniqueness: { scope: :project_id }, if: :project_level?
  validates :type, uniqueness: { scope: :group_id }, if: :group_level?
  validate :validate_belongs_to_project_or_group

  scope :external_issue_trackers, -> { where(category: 'issue_tracker').active }
  scope :external_wikis, -> { where(type: 'ExternalWikiService').active }
  scope :active, -> { where(active: true) }
  scope :by_type, -> (type) { where(type: type) }
  scope :by_active_flag, -> (flag) { where(active: flag) }
  scope :inherit_from_id, -> (id) { where(inherit_from_id: id) }
  scope :inherit, -> { where.not(inherit_from_id: nil) }
  scope :for_group, -> (group) { where(group_id: group, type: available_integration_types(include_project_specific: false)) }
  scope :for_instance, -> { where(instance: true, type: available_integration_types(include_project_specific: false)) }

  scope :push_hooks, -> { where(push_events: true, active: true) }
  scope :tag_push_hooks, -> { where(tag_push_events: true, active: true) }
  scope :issue_hooks, -> { where(issues_events: true, active: true) }
  scope :confidential_issue_hooks, -> { where(confidential_issues_events: true, active: true) }
  scope :merge_request_hooks, -> { where(merge_requests_events: true, active: true) }
  scope :note_hooks, -> { where(note_events: true, active: true) }
  scope :confidential_note_hooks, -> { where(confidential_note_events: true, active: true) }
  scope :job_hooks, -> { where(job_events: true, active: true) }
  scope :pipeline_hooks, -> { where(pipeline_events: true, active: true) }
  scope :wiki_page_hooks, -> { where(wiki_page_events: true, active: true) }
  scope :deployment_hooks, -> { where(deployment_events: true, active: true) }
  scope :alert_hooks, -> { where(alert_events: true, active: true) }
  scope :deployment, -> { where(category: 'deployment') }

  # Provide convenient accessor methods for each serialized property.
  # Also keep track of updated properties in a similar way as ActiveModel::Dirty
  def self.prop_accessor(*args)
    args.each do |arg|
      class_eval <<~RUBY, __FILE__, __LINE__ + 1
        unless method_defined?(arg)
          def #{arg}
            properties['#{arg}']
          end
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
      RUBY
    end
  end

  # Provide convenient boolean accessor methods for each serialized property.
  # Also keep track of updated properties in a similar way as ActiveModel::Dirty
  def self.boolean_accessor(*args)
    self.prop_accessor(*args)

    args.each do |arg|
      class_eval <<~RUBY, __FILE__, __LINE__ + 1
        def #{arg}
          Gitlab::Utils.to_boolean(properties['#{arg}'])
        end

        def #{arg}?
          # '!!' is used because nil or empty string is converted to nil
          !!#{arg}
        end
      RUBY
    end
  end

  def self.to_param
    raise NotImplementedError
  end

  def self.event_names
    self.supported_events.map { |event| IntegrationsHelper.integration_event_field_name(event) }
  end

  def self.supported_event_actions
    %w[]
  end

  def self.supported_events
    %w[commit push tag_push issue confidential_issue merge_request wiki_page]
  end

  def self.default_test_event
    'push'
  end

  def self.event_description(event)
    IntegrationsHelper.integration_event_description(event)
  end

  def self.find_or_initialize_non_project_specific_integration(name, instance: false, group_id: nil)
    return unless name.in?(available_integration_names(include_project_specific: false))

    integration_name_to_model(name).find_or_initialize_by(instance: instance, group_id: group_id)
  end

  def self.find_or_initialize_all_non_project_specific(scope)
    scope + build_nonexistent_integrations_for(scope)
  end

  def self.build_nonexistent_integrations_for(scope)
    nonexistent_integration_types_for(scope).map do |type|
      integration_type_to_model(type).new
    end
  end
  private_class_method :build_nonexistent_integrations_for

  # Returns a list of integration types that do not exist in the given scope.
  # Example: ["AsanaService", ...]
  def self.nonexistent_integration_types_for(scope)
    # Using #map instead of #pluck to save one query count. This is because
    # ActiveRecord loaded the object here, so we don't need to query again later.
    available_integration_types(include_project_specific: false) - scope.map(&:type)
  end
  private_class_method :nonexistent_integration_types_for

  # Returns a list of available integration names.
  # Example: ["asana", ...]
  # @deprecated
  def self.available_integration_names(include_project_specific: true, include_dev: true)
    names = integration_names
    names += project_specific_integration_names if include_project_specific
    names += dev_integration_names if include_dev

    names.sort_by(&:downcase)
  end

  def self.integration_names
    INTEGRATION_NAMES
  end

  def self.dev_integration_names
    return [] unless Rails.env.development?

    DEV_INTEGRATION_NAMES
  end

  def self.project_specific_integration_names
    PROJECT_SPECIFIC_INTEGRATION_NAMES
  end

  # Returns a list of available integration types.
  # Example: ["AsanaService", ...]
  def self.available_integration_types(include_project_specific: true, include_dev: true)
    available_integration_names(include_project_specific: include_project_specific, include_dev: include_dev).map do
      integration_name_to_type(_1)
    end
  end

  # Returns the model for the given integration name.
  # Example: "asana" => Integrations::Asana
  def self.integration_name_to_model(name)
    type = integration_name_to_type(name)
    integration_type_to_model(type)
  end

  # Returns the STI type for the given integration name.
  # Example: "asana" => "AsanaService"
  def self.integration_name_to_type(name)
    "#{name}_service".camelize
  end

  # Returns the model for the given STI type.
  # Example: "AsanaService" => Integrations::Asana
  def self.integration_type_to_model(type)
    Gitlab::Integrations::StiType.new.cast(type).constantize
  end
  private_class_method :integration_type_to_model

  def self.build_from_integration(integration, project_id: nil, group_id: nil)
    new_integration = integration.dup

    if integration.supports_data_fields?
      data_fields = integration.data_fields.dup
      data_fields.integration = new_integration
    end

    new_integration.instance = false
    new_integration.project_id = project_id
    new_integration.group_id = group_id
    new_integration.inherit_from_id = integration.id if integration.instance_level? || integration.group_level?
    new_integration
  end

  def self.instance_exists_for?(type)
    exists?(instance: true, type: type)
  end

  def self.default_integration(type, scope)
    closest_group_integration(type, scope) || instance_level_integration(type)
  end

  def self.closest_group_integration(type, scope)
    group_ids = scope.ancestors.select(:id)
    array = group_ids.to_sql.present? ? "array(#{group_ids.to_sql})" : 'ARRAY[]'

    where(type: type, group_id: group_ids, inherit_from_id: nil)
      .order(Arel.sql("array_position(#{array}::bigint[], #{table_name}.group_id)"))
      .first
  end
  private_class_method :closest_group_integration

  def self.instance_level_integration(type)
    find_by(type: type, instance: true)
  end
  private_class_method :instance_level_integration

  def self.create_from_active_default_integrations(scope, association)
    group_ids = sorted_ancestors(scope).select(:id)
    array = group_ids.to_sql.present? ? "array(#{group_ids.to_sql})" : 'ARRAY[]'

    from_union([
      active.where(instance: true),
      active.where(group_id: group_ids, inherit_from_id: nil)
    ]).order(Arel.sql("type ASC, array_position(#{array}::bigint[], #{table_name}.group_id), instance DESC")).group_by(&:type).each do |type, records|
      build_from_integration(records.first, association => scope.id).save
    end
  end

  def self.inherited_descendants_from_self_or_ancestors_from(integration)
    inherit_from_ids =
      where(type: integration.type, group: integration.group.self_and_ancestors)
        .or(where(type: integration.type, instance: true)).select(:id)

    from_union([
      where(type: integration.type, inherit_from_id: inherit_from_ids, group: integration.group.descendants),
      where(type: integration.type, inherit_from_id: inherit_from_ids, project: Project.in_namespace(integration.group.self_and_descendants))
    ])
  end

  def activated?
    active
  end

  def operating?
    active && persisted?
  end

  def show_active_box?
    true
  end

  def editable?
    true
  end

  def category
    read_attribute(:category).to_sym
  end

  def initialize_properties
    self.properties = {} if has_attribute?(:properties) && properties.nil?
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

  def fields
    # implement inside child
    []
  end

  # Expose a list of fields in the JSON endpoint.
  #
  # This list is used in `Integration#as_json(only: json_fields)`.
  def json_fields
    %w[active]
  end

  def to_integration_hash
    as_json(methods: :type, except: %w[id instance project_id group_id])
  end

  def to_data_fields_hash
    data_fields.as_json(only: data_fields.class.column_names).except('id', 'service_id')
  end

  def event_channel_names
    []
  end

  def event_names
    self.class.event_names
  end

  def event_field(event)
    nil
  end

  def api_field_names
    fields.map { |field| field[:name] }
      .reject { |field_name| field_name =~ /(password|token|key|title|description)/ }
  end

  def global_fields
    fields
  end

  def configurable_events
    events = supported_events

    # No need to disable individual triggers when there is only one
    if events.count == 1
      []
    else
      events
    end
  end

  def configurable_event_actions
    self.class.supported_event_actions
  end

  def supported_events
    self.class.supported_events
  end

  def default_test_event
    self.class.default_test_event
  end

  def execute(data)
    # implement inside child
  end

  def test(data)
    # default implementation
    result = execute(data)
    { success: result.present?, result: result }
  end

  # Disable test for instance-level and group-level integrations.
  # https://gitlab.com/gitlab-org/gitlab/-/issues/213138
  def testable?
    project_level?
  end

  def project_level?
    project_id.present?
  end

  def group_level?
    group_id.present?
  end

  def instance_level?
    instance?
  end

  def parent
    project || group
  end

  # Returns a hash of the properties that have been assigned a new value since last save,
  # indicating their original values (attr => original value).
  # ActiveRecord does not provide a mechanism to track changes in serialized keys,
  # so we need a specific implementation for integration properties.
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

  # override if needed
  def supports_data_fields?
    false
  end

  private

  # Ancestors sorted by hierarchy depth in bottom-top order.
  def self.sorted_ancestors(scope)
    if scope.root_ancestor.use_traversal_ids?
      Namespace.from(scope.ancestors(hierarchy_order: :asc))
    else
      scope.ancestors
    end
  end

  def validate_belongs_to_project_or_group
    errors.add(:project_id, 'The service cannot belong to both a project and a group') if project_level? && group_level?
  end

  def validate_recipients?
    activated? && !importing?
  end
end

Integration.prepend_mod_with('Integration')
