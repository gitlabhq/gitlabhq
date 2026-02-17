# frozen_string_literal: true

module Integrations
  module Base
    module ChatNotification
      extend ActiveSupport::Concern
      extend Gitlab::Utils::Override

      include ChatMessage
      include NotificationBranchSelection
      include NotificationPipelineStatusSelection

      prepend_mod_with('Integrations::Base::ChatNotification') # rubocop:disable Cop/InjectEnterpriseEditionModule -- need to prepend before class_methods block. See https://gitlab.com/gitlab-org/gitlab/-/merge_requests/171515#note_2197128497

      SUPPORTED_EVENTS = %w[
        push issue confidential_issue merge_request note confidential_note
        tag_push pipeline wiki_page deployment incident work_item confidential_work_item
      ].freeze

      GROUP_ONLY_SUPPORTED_EVENTS = %w[group_mention group_confidential_mention].freeze

      SUPPORTED_EVENTS_FOR_LABEL_FILTER = %w[issue confidential_issue merge_request note confidential_note
        incident work_item confidential_work_item].freeze

      EVENT_CHANNEL = proc { |event| "#{event}_channel" }

      LABEL_NOTIFICATION_BEHAVIOURS = [
        MATCH_ANY_LABEL = 'match_any',
        MATCH_ALL_LABELS = 'match_all'
      ].freeze

      SECRET_MASK = '************'

      class_methods do
        extend Gitlab::Utils::Override

        override :supported_events
        def supported_events
          SUPPORTED_EVENTS
        end

        def requires_webhook?
          true
        end

        # Allows chat integrations to indicate there are specific addressable_url
        # validation options to use instead of using default public_url options
        def has_public_url_validation_options?
          false
        end

        def event_channel_name(event)
          EVENT_CHANNEL[event]
        end
      end

      included do
        attribute :category, default: 'chat'

        prop_accessor :webhook, :username, :channel, :branches_to_be_notified, :labels_to_be_notified,
          :labels_to_be_notified_behavior, :notify_only_default_branch

        # Custom serialized properties initialization
        prop_accessor(*SUPPORTED_EVENTS.map { |event| EVENT_CHANNEL[event] })
        prop_accessor(*GROUP_ONLY_SUPPORTED_EVENTS.map { |event| EVENT_CHANNEL[event] })

        validates :webhook,
          presence: true,
          if: ->(integration) { integration.activated? && integration.class.requires_webhook? }
        validates :webhook,
          public_url: true,
          if: ->(integration) {
            !integration.class.has_public_url_validation_options? &&
              integration.activated? &&
              integration.class.requires_webhook?
          }
        validates :labels_to_be_notified_behavior,
          inclusion: { in: LABEL_NOTIFICATION_BEHAVIOURS },
          allow_blank: true,
          if: :activated?
        validate :validate_channel_limit, if: :activated?
      end

      def initialize_properties
        super

        if properties.empty?
          self.notify_only_broken_pipelines = true if respond_to?(:notify_only_broken_pipelines)
          if respond_to?(:notify_only_when_pipeline_status_changes)
            self.notify_only_when_pipeline_status_changes = false
          end

          self.branches_to_be_notified = "default"
          self.labels_to_be_notified_behavior = MATCH_ANY_LABEL
        elsif !notify_only_default_branch.nil?
          # In older versions, there was only a boolean property named
          # `notify_only_default_branch`. Now we have a string property named
          # `branches_to_be_notified`. Instead of doing a background migration, we
          # opted to set a value for the new property based on the old one, if
          # users haven't specified one already. When users edit the integration and
          # select a value for this new property, it will override everything.

          self.branches_to_be_notified ||= notify_only_default_branch == 'true' ? "default" : "all"
        end
      end

      override :configurable_events
      def configurable_events
        # Exclude work item events from UI - they use issue event settings
        super - %w[work_item confidential_work_item]
      end

      def confidential_issue_channel
        properties['confidential_issue_channel'].presence || properties['issue_channel']
      end

      def confidential_note_channel
        properties['confidential_note_channel'].presence || properties['note_channel']
      end

      def fields
        super + build_event_channels
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

        # Map work_item events to issue consistently for event routing
        event = data[:event_type] || object_kind
        mapped_event = map_work_item_event(event)
        channels = channels_for_event(mapped_event)

        opts = {}
        opts[:channel] = channels if channels.present?
        opts[:username] = username if username

        if notify(message, opts)
          log_usage(mapped_event, user_id_from_hook_data(data))
          return true
        end

        false
      end

      def event_channel_names
        return [] unless configurable_channels?

        supported_events.map { |event| self.class.event_channel_name(event) }
      end

      override :api_field_names
      def api_field_names
        if mask_configurable_channels?
          super - event_channel_names
        else
          super
        end
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

      def event_channel_value(event)
        field_name = self.class.event_channel_name(event)

        public_send(field_name) # rubocop:disable GitlabSecurity/PublicSend -- Legacy use
      end

      def channel_limit_per_event
        10
      end

      def mask_configurable_channels?
        false
      end

      override :sections
      def sections
        [
          {
            type: ::Integration::SECTION_TYPE_CONNECTION,
            title: s_('Integrations|Connection details'),
            description: help
          },
          {
            type: ::Integration::SECTION_TYPE_TRIGGER,
            title: s_('Integrations|Trigger'),
            description: s_('Integrations|An event will be triggered when one of the following items happen.')
          },
          {
            type: ::Integration::SECTION_TYPE_CONFIGURATION,
            title: s_('Integrations|Notification settings'),
            description: s_('Integrations|Configure the scope of notifications.')
          }
        ]
      end

      private

      def should_execute?(object_kind)
        mapped_event_type = map_work_item_event(object_kind)

        supported_events.include?(mapped_event_type) &&
          (!self.class.requires_webhook? || webhook.present?)
      end

      def map_work_item_event(event)
        case event
        when 'work_item'
          'issue'
        when 'confidential_work_item'
          'confidential_issue'
        else
          event
        end
      end

      def log_usage(_, _)
        # Implement in child class
      end

      def labels_to_be_notified_list
        return [] if labels_to_be_notified.nil?

        labels_to_be_notified.delete('~').split(',').map(&:strip)
      end

      def notify_label?(data)
        object_kind = data[:object_kind]
        mapped_object_kind = map_work_item_event(object_kind)

        unless SUPPORTED_EVENTS_FOR_LABEL_FILTER.include?(mapped_object_kind) && labels_to_be_notified.present?
          return true
        end

        labels = data[:labels] ||
          data.dig(:issue, :labels) ||
          data.dig(:merge_request, :labels) ||
          data.dig(:object_attributes, :labels)

        return false if labels.blank?

        label_titles = labels.filter_map { |label| label[:title] }
        matching_labels = labels_to_be_notified_list & label_titles

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

      # rubocop:disable Metrics/CyclomaticComplexity -- Legacy use
      def get_message(object_kind, data)
        case object_kind
        when "push", "tag_push"
          Integrations::ChatMessage::PushMessage.new(data) if notify_for_ref?(data)
        when "issue", "work_item", "confidential_work_item"
          # Skip incidents in work_item events - they should be handled separately
          return if skip_work_item_incident?(object_kind, data)

          Integrations::ChatMessage::IssueMessage.new(data) unless update?(data)
        when "incident"
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
        when "group_mention"
          Integrations::ChatMessage::GroupMentionMessage.new(data)
        end
      end
      # rubocop:enable Metrics/CyclomaticComplexity

      def build_event_channels
        event_channel_names.map do |channel_field|
          Field.new(
            name: channel_field,
            type: :text,
            placeholder: default_channel_placeholder,
            integration_class: self
          )
        end
      end

      def project_name
        project.try(:full_name)
      end

      def project_url
        project.try(:web_url)
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

        # No need to check protected branches when there is no ref
        return true if ref.blank?

        # Skip protected branch check because it doesn't support tags
        return true if Gitlab::Git.tag_ref?(project.repository.expand_ref(ref) || ref)

        notify_for_branch?(data)
      end

      def channels_for_event(event)
        # Map work_item events to appropriate issue channels
        mapped_event = map_work_item_event(event)
        channel_names = event_channel_value(mapped_event).presence || channel.presence
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
          next unless count > channel_limit_per_event

          errors.add(
            self.class.event_channel_name(event).to_sym,
            format(
              s_('SlackIntegration|cannot have more than %{limit} channels'),
              limit: channel_limit_per_event
            )
          )
        end
      end

      def skip_work_item_incident?(object_kind, data)
        object_kind.in?(%w[work_item confidential_work_item]) &&
          data.dig(:object_attributes, :type) == "Incident"
      end
    end
  end
end
