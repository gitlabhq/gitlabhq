class PipelinesEmailService < Service
  prop_accessor :recipients
  boolean_accessor :notify_only_broken_pipelines
  validates :recipients, presence: true, if: :activated?

  def initialize_properties
    self.properties ||= { notify_only_broken_pipelines: true }
  end

  def title
    'Pipelines emails'
  end

  def description
    'Email the pipelines status to a list of recipients.'
  end

  def to_param
    'pipelines_email'
  end

  def supported_events
    %w[pipeline]
  end

  def execute(data, force: false)
    return unless supported_events.include?(data[:object_kind])
    return unless force || should_pipeline_be_notified?(data)

    all_recipients = retrieve_recipients(data)

    return unless all_recipients.any?

    pipeline = Ci::Pipeline.find(data[:object_attributes][:id])
    Ci::SendPipelineNotificationService.new(pipeline).execute(all_recipients)
  end

  def can_test?
    project.pipelines.any?
  end

  def disabled_title
    'Please setup a pipeline on your repository.'
  end

  def test_data(project, user)
    data = Gitlab::DataBuilder::Pipeline.build(project.pipelines.last)
    data[:user] = user.hook_attrs
    data
  end

  def fields
    [
      { type: 'textarea',
        name: 'recipients',
        placeholder: 'Emails separated by comma' },
      { type: 'checkbox',
        name: 'notify_only_broken_pipelines' },
    ]
  end

  def test(data)
    result = execute(data, force: true)

    { success: true, result: result }
  rescue StandardError => error
    { success: false, result: error }
  end

  def should_pipeline_be_notified?(data)
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
    recipients.to_s.split(',').reject(&:blank?)
  end
end
