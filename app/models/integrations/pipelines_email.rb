# frozen_string_literal: true

module Integrations
  class PipelinesEmail < Integration
    include NotificationBranchSelection

    RECIPIENTS_LIMIT = 30

    validates :recipients, presence: true, if: :validate_recipients?
    validate :number_of_recipients_within_limit, if: :validate_recipients?

    field :recipients,
      type: :textarea,
      help: -> { _('Comma-separated list of recipient email addresses.') },
      required: true

    field :notify_only_broken_pipelines,
      type: :checkbox,
      description: -> { _('Send notifications for broken pipelines.') }

    field :notify_only_default_branch,
      type: :checkbox,
      api_only: true,
      description: -> { _('Send notifications for the default branch.') }

    field :branches_to_be_notified,
      type: :select,
      title: -> { s_('Integrations|Branches for which notifications are to be sent') },
      description: -> {
                     _('Branches to send notifications for. Valid options are `all`, `default`, `protected`, ' \
                       'and `default_and_protected`. The default value is `default`.')
                   },
      choices: branch_choices

    def initialize_properties
      super

      if properties.blank?
        self.notify_only_broken_pipelines = true
        self.branches_to_be_notified = "default"
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

    def self.title
      _('Pipeline status emails')
    end

    def self.description
      _('Email the pipeline status to a list of recipients.')
    end

    def self.to_param
      'pipelines_email'
    end

    def self.supported_events
      %w[pipeline]
    end

    def self.default_test_event
      'pipeline'
    end

    def execute(data, force: false)
      return unless supported_events.include?(data[:object_kind])
      return unless force || should_pipeline_be_notified?(data)

      all_recipients = retrieve_recipients

      return unless all_recipients.any?

      pipeline_id = data[:object_attributes][:id]
      PipelineNotificationWorker.new.perform(pipeline_id, 'recipients' => all_recipients)
    end

    def testable?
      project&.ci_pipelines&.any?
    end

    def test(data)
      result = execute(data, force: true)

      { success: true, result: result }
    rescue StandardError => e
      { success: false, result: e }
    end

    def should_pipeline_be_notified?(data)
      notify_for_branch?(data) && notify_for_pipeline?(data)
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

    def retrieve_recipients
      recipients.to_s.split(/[,\r\n ]+/).reject(&:empty?)
    end

    private

    def number_of_recipients_within_limit
      return if recipients.blank?

      if retrieve_recipients.size > RECIPIENTS_LIMIT
        errors.add(:recipients, s_("Integrations|can't exceed %{recipients_limit}") % { recipients_limit: RECIPIENTS_LIMIT })
      end
    end
  end
end
