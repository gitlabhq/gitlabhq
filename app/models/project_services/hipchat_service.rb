# frozen_string_literal: true

class HipchatService < Service
  include ActionView::Helpers::SanitizeHelper

  MAX_COMMITS = 3
  HIPCHAT_ALLOWED_TAGS = %w[
    a b i strong em br img pre code
    table th tr td caption colgroup col thead tbody tfoot
    ul ol li dl dt dd
  ].freeze

  prop_accessor :token, :room, :server, :color, :api_version
  boolean_accessor :notify_only_broken_pipelines, :notify
  validates :token, presence: true, if: :activated?

  def initialize_properties
    if properties.nil?
      self.properties = {}
      self.notify_only_broken_pipelines = true
    end
  end

  def title
    'HipChat'
  end

  def description
    'Private group chat and IM'
  end

  def self.to_param
    'hipchat'
  end

  def fields
    [
      { type: 'text', name: 'token',     placeholder: 'Room token', required: true },
      { type: 'text', name: 'room',      placeholder: 'Room name or ID' },
      { type: 'checkbox', name: 'notify' },
      { type: 'select', name: 'color', choices: %w(yellow red green purple gray random) },
      { type: 'text', name: 'api_version', title: _('API version'),
        placeholder: 'Leave blank for default (v2)' },
      { type: 'text', name: 'server',
        placeholder: 'Leave blank for default. https://hipchat.example.com' },
      { type: 'checkbox', name: 'notify_only_broken_pipelines' }
    ]
  end

  def self.supported_events
    %w(push issue confidential_issue merge_request note confidential_note tag_push pipeline)
  end

  def execute(data)
    # We removed the hipchat gem due to https://gitlab.com/gitlab-org/gitlab/-/issues/325851#note_537143149
    # HipChat is unusable anyway, so do nothing in this method
  end

  def test(data)
    begin
      result = execute(data)
    rescue StandardError => error
      return { success: false, result: error }
    end

    { success: true, result: result }
  end

  private

  def message_options(data = nil)
    { notify: notify.present? && Gitlab::Utils.to_boolean(notify), color: message_color(data) }
  end

  def render_line(text)
    markdown(text.lines.first.chomp, pipeline: :single_line) if text
  end

  def markdown(text, options = {})
    return "" unless text

    context = {
      project: project,
      pipeline: :email
    }

    Banzai.render(text, context)

    context.merge!(options)

    html = Banzai.render_and_post_process(text, context)
    sanitized_html = sanitize(html, tags: HIPCHAT_ALLOWED_TAGS, attributes: %w[href title alt])

    sanitized_html.truncate(200, separator: ' ', omission: '...')
  end

  def format_title(title)
    "<b>#{render_line(title)}</b>"
  end

  def message_color(data)
    pipeline_status_color(data) || color || 'yellow'
  end

  def pipeline_status_color(data)
    return unless data && data[:object_kind] == 'pipeline'

    case data[:object_attributes][:status]
    when 'success'
      'green'
    else
      'red'
    end
  end

  def project_name
    project.full_name.gsub(/\s/, '')
  end

  def project_url
    project.web_url
  end

  def project_link
    "<a href=\"#{project_url}\">#{project_name}</a>"
  end

  def update?(data)
    data[:object_attributes][:action] == 'update'
  end

  def humanized_status(status)
    case status
    when 'success'
      'passed'
    else
      status
    end
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
end
