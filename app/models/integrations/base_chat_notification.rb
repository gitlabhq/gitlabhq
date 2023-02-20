# frozen_string_literal: true

# Base class for Chat notifications integrations
# This class is not meant to be used directly, but only to inherit from.

module Integrations
  class BaseChatNotification < Integration
    include ChatMessage
    include NotificationBranchSelection

    SUPPORTED_EVENTS = %w[
      push issue confidential_issue merge_request note confidential_note
      tag_push pipeline wiki_page deployment incident
    ].freeze

    SUPPORTED_EVENTS_FOR_LABEL_FILTER = %w[issue confidential_issue merge_request note confidential_note].freeze

    EVENT_CHANNEL = proc { |event| "#{event}_channel" }

    LABEL_NOTIFICATION_BEHAVIOURS = [
      MATCH_ANY_LABEL = 'match_any',
      MATCH_ALL_LABELS = 'match_all'
    ].freeze

    SECRET_MASK = '************'
    CHANNEL_LIMIT_PER_EVENT = 10

    attribute :category, default: 'chat'

    prop_accessor :webhook, :username, :channel, :branches_to_be_notified, :labels_to_be_notified, :labels_to_be_notified_behavior

    # Custom serialized properties initialization
    prop_accessor(*SUPPORTED_EVENTS.map { |event| EVENT_CHANNEL[event] })

    boolean_accessor :notify_only_broken_pipelines, :notify_only_default_branch

    validates :webhook,
              presence: true,
              public_url: true,
              if: -> (integration) { integration.activated? && integration.requires_webhook? }
    validates :labels_to_be_notified_behavior, inclusion: { in: LABEL_NOTIFICATION_BEHAVIOURS }, allow_blank: true, if: :activated?
    validate :validate_channel_limit, if: :activated?

    def initialize_properties
      super

      if properties.empty?
        self.notify_only_broken_pipelines = true
        self.branches_to_be_notified = "default"
        self.labels_to_be_notified_behavior = MATCH_ANY_LABEL
      elsif !self.notify_only_default_branch.nil?
        # In older versions, there was only a boolean property named
        # `notify_only_default_branch`. Now we have a string property named
        # `branches_to_be_notified`. Instead of doing a background migration, we
        # opted to set a value for the new property based on the old one, if
        # users haven't specified one already. When users edit the integration and
        # select a value for this new property, it will override everything.

        self.branches_to_be_notified ||= notify_only_default_branch? ? "default" : "all"
      end
    end

    def confidential_issue_channel
      properties['confidential_issue_channel'].presence || properties['issue_channel']
    end

    def confidential_note_channel
      properties['confidential_note_channel'].presence || properties['note_channel']
    end

    def self.supported_events
      SUPPORTED_EVENTS
    end

    def fields
      default_fields + build_event_channels
    end

    def default_fields
      [
        {
          type: 'checkbox',
          section: SECTION_TYPE_CONFIGURATION,
          name: 'notify_only_broken_pipelines',
          help: 'Do not send notifications for successful pipelines.'
        }.freeze,
        {
          type: 'select',
          section: SECTION_TYPE_CONFIGURATION,
          name: 'branches_to_be_notified',
          title: s_('Integrations|Branches for which notifications are to be sent'),
          choices: self.class.branch_choices
        }.freeze,
        {
          type: 'text',
          section: SECTION_TYPE_CONFIGURATION,
          name: 'labels_to_be_notified',
          placeholder: '~backend,~frontend',
          help: 'Send notifications for issue, merge request, and comment events with the listed labels only. Leave blank to receive notifications for all events.'
        }.freeze,
        {
          type: 'select',
          section: SECTION_TYPE_CONFIGURATION,
          name: 'labels_to_be_notified_behavior',
          choices: [
            ['Match any of the labels', MATCH_ANY_LABEL],
            ['Match all of the labels', MATCH_ALL_LABELS]
          ]
        }.freeze
      ].tap do |fields|
        next unless requires_webhook?

        fields.unshift(
          { type: 'text', name: 'webhook', help: webhook_help, required: true }.freeze,
          { type: 'text', name: 'username', placeholder: 'GitLab-integration' }.freeze
        )
      end.freeze
    end

    def execute(data)
      object_kind = data[:object_kind]

      return false unless should_execute?(object_kind)

      data = custom_data(data)

      return false unless notify_label?(data)

      # WebHook events often have an 'update' event that follows a 'open' or
      # 'close' action. Ignore update events for now to prevent duplicate
      # messages from arriving.

      message = get_message(object_kind, data)

      return false unless message

      event = data[:event_type] || object_kind
      channels = channels_for_event(event)

      opts = {}
      opts[:channel] = channels if channels.present?
      opts[:username] = username if username

      if notify(message, opts)
        log_usage(event, user_id_from_hook_data(data))
        return true
      end

      false
    end

    def event_channel_names
      return [] unless configurable_channels?

      supported_events.map { |event| event_channel_name(event) }
    end

    def form_fields
      super.reject { |field| field[:name].end_with?('channel') }
    end

    def default_channel_placeholder
      raise NotImplementedError
    end

    def webhook_help
      raise NotImplementedError
    end

    # With some integrations the webhook is already tied to a specific channel,
    # for others the channels are configurable for each event.
    def configurable_channels?
      false
    end

    def event_channel_name(event)
      EVENT_CHANNEL[event]
    end

    def event_channel_value(event)
      field_name = event_channel_name(event)
      self.public_send(field_name) # rubocop:disable GitlabSecurity/PublicSend
    end

    def requires_webhook?
      true
    end

    private

    def should_execute?(object_kind)
      supported_events.include?(object_kind) &&
        (!requires_webhook? || webhook.present?)
    end

    def log_usage(_, _)
      # Implement in child class
    end

    def labels_to_be_notified_list
      return [] if labels_to_be_notified.nil?

      labels_to_be_notified.delete('~').split(',').map(&:strip)
    end

    def notify_label?(data)
      return true unless SUPPORTED_EVENTS_FOR_LABEL_FILTER.include?(data[:object_kind]) && labels_to_be_notified.present?

      labels = data[:labels] || data.dig(:issue, :labels) || data.dig(:merge_request, :labels) || data.dig(:object_attributes, :labels)

      return false if labels.blank?

      matching_labels = labels_to_be_notified_list & labels.pluck(:title)

      if labels_to_be_notified_behavior == MATCH_ALL_LABELS
        labels_to_be_notified_list.difference(matching_labels).empty?
      else
        matching_labels.any?
      end
    end

    def user_id_from_hook_data(data)
      data.dig(:user, :id) || data[:user_id]
    end

    # every notifier must implement this independently
    def notify(message, opts)
      raise NotImplementedError
    end

    def custom_data(data)
      data.merge(project_url: project_url, project_name: project_name).with_indifferent_access
    end

    # rubocop:disable Metrics/CyclomaticComplexity
    def get_message(object_kind, data)
      case object_kind
      when "push", "tag_push"
        Integrations::ChatMessage::PushMessage.new(data) if notify_for_ref?(data)
      when "issue"
        Integrations::ChatMessage::IssueMessage.new(data) unless update?(data)
      when "merge_request"
        Integrations::ChatMessage::MergeMessage.new(data) unless update?(data)
      when "note"
        Integrations::ChatMessage::NoteMessage.new(data)
      when "pipeline"
        Integrations::ChatMessage::PipelineMessage.new(data) if should_pipeline_be_notified?(data)
      when "wiki_page"
        Integrations::ChatMessage::WikiPageMessage.new(data)
      when "deployment"
        Integrations::ChatMessage::DeploymentMessage.new(data) if notify_for_ref?(data)
      when "incident"
        Integrations::ChatMessage::IssueMessage.new(data) unless update?(data)
      end
    end
    # rubocop:enable Metrics/CyclomaticComplexity

    def build_event_channels
      event_channel_names.map do |channel_field|
        { type: 'text', name: channel_field, placeholder: default_channel_placeholder }
      end
    end

    def project_name
      project.full_name
    end

    def project_url
      project.web_url
    end

    def update?(data)
      data[:object_attributes][:action] == 'update'
    end

    def should_pipeline_be_notified?(data)
      notify_for_ref?(data) && notify_for_pipeline?(data)
    end

    def notify_for_ref?(data)
      return true if data[:object_kind] == 'tag_push'

      ref = data[:ref] || data.dig(:object_attributes, :ref)
      return true if ref.blank? # No need to check protected branches when there is no ref
      return true if Gitlab::Git.tag_ref?(project.repository.expand_ref(ref) || ref) # Skip protected branch check because it doesn't support tags

      notify_for_branch?(data)
    end

    def notify_for_pipeline?(data)
      case data[:object_attributes][:status]
      when 'success'
        !notify_only_broken_pipelines?
      when 'failed'
        true
      else
        false
      end
    end

    def channels_for_event(event)
      channel_names = event_channel_value(event).presence || channel.presence
      return [] unless channel_names

      channel_names.split(',').map(&:strip).uniq
    end

    def unique_channels
      @unique_channels ||= supported_events.flat_map do |event|
        channels_for_event(event)
      end.uniq
    end

    def validate_channel_limit
      supported_events.each do |event|
        count = channels_for_event(event).count
        next unless count > CHANNEL_LIMIT_PER_EVENT

        errors.add(
          event_channel_name(event).to_sym,
          format(
            s_('SlackIntegration|cannot have more than %{limit} channels'),
            limit: CHANNEL_LIMIT_PER_EVENT
          )
        )
      end
    end
  end
end

Integrations::BaseChatNotification.prepend_mod_with('Integrations::BaseChatNotification')
