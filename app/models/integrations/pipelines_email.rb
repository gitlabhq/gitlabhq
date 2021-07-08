# frozen_string_literal: true

module Integrations
  class PipelinesEmail < Integration
    include NotificationBranchSelection

    prop_accessor :recipients, :branches_to_be_notified
    boolean_accessor :notify_only_broken_pipelines, :notify_only_default_branch
    validates :recipients, presence: true, if: :validate_recipients?

    def initialize_properties
      if properties.nil?
        self.properties = {}
        self.notify_only_broken_pipelines = true
        self.branches_to_be_notified = "default"
      elsif !self.notify_only_default_branch.nil?
        # In older versions, there was only a boolean property named
        # `notify_only_default_branch`. Now we have a string property named
        # `branches_to_be_notified`. Instead of doing a background migration, we
        # opted to set a value for the new property based on the old one, if
        # users hasn't specified one already. When users edit the service and
        # selects a value for this new property, it will override everything.

        self.branches_to_be_notified ||= notify_only_default_branch? ? "default" : "all"
      end
    end

    def title
      _('Pipeline status emails')
    end

    def description
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

      all_recipients = retrieve_recipients(data)

      return unless all_recipients.any?

      pipeline_id = data[:object_attributes][:id]
      PipelineNotificationWorker.new.perform(pipeline_id, recipients: all_recipients)
    end

    def testable?
      project&.ci_pipelines&.any?
    end

    def fields
      [
        { type: 'textarea',
          name: 'recipients',
          help: _('Comma-separated list of email addresses.'),
          required: true },
        { type: 'checkbox',
          name: 'notify_only_broken_pipelines' },
        { type: 'select',
          name: 'branches_to_be_notified',
          choices: branch_choices }
      ]
    end

    def test(data)
      result = execute(data, force: true)

      { success: true, result: result }
    rescue StandardError => error
      { success: false, result: error }
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

    def retrieve_recipients(data)
      recipients.to_s.split(/[,\r\n ]+/).reject(&:empty?)
    end
  end
end
