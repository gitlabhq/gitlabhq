# frozen_string_literal: true

class PipelinesEmailService < Service
  prop_accessor :recipients
  boolean_accessor :notify_only_broken_pipelines, :notify_only_default_branch
  validates :recipients, presence: true, if: :valid_recipients?

  def initialize_properties
    self.properties ||= { notify_only_broken_pipelines: true, notify_only_default_branch: false }
  end

  def title
    _('Pipelines emails')
  end

  def description
    _('Email the pipelines status to a list of recipients.')
  end

  def self.to_param
    'pipelines_email'
  end

  def self.supported_events
    %w[pipeline]
  end

  def execute(data, force: false)
    return unless supported_events.include?(data[:object_kind])
    return unless force || should_pipeline_be_notified?(data)

    all_recipients = retrieve_recipients(data)

    return unless all_recipients.any?

    pipeline_id = data[:object_attributes][:id]
    PipelineNotificationWorker.new.perform(pipeline_id, all_recipients)
  end

  def can_test?
    project.ci_pipelines.any?
  end

  def test_data(project, user)
    data = Gitlab::DataBuilder::Pipeline.build(project.ci_pipelines.last)
    data[:user] = user.hook_attrs
    data
  end

  def fields
    [
      { type: 'textarea',
        name: 'recipients',
        placeholder: _('Emails separated by comma'),
        required: true },
      { type: 'checkbox',
        name: 'notify_only_broken_pipelines' },
      { type: 'checkbox',
        name: 'notify_only_default_branch' }
    ]
  end

  def test(data)
    result = execute(data, force: true)

    { success: true, result: result }
  rescue StandardError => error
    { success: false, result: error }
  end

  def should_pipeline_be_notified?(data)
    notify_for_pipeline_branch?(data) && notify_for_pipeline?(data)
  end

  def notify_for_pipeline_branch?(data)
    return true unless notify_only_default_branch?

    data[:object_attributes][:ref] == data[:project][:default_branch]
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
    recipients.to_s.split(/[,(?:\r?\n) ]+/).reject(&:empty?)
  end
end
