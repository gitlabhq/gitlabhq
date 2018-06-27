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
      { type: 'text', name: 'api_version',
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
    return unless supported_events.include?(data[:object_kind])

    message = create_message(data)
    return unless message.present?

    gate[room].send('GitLab', message, message_options(data)) # rubocop:disable GitlabSecurity/PublicSend
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

  def gate
    options = { api_version: api_version.present? ? api_version : 'v2' }
    options[:server_url] = server unless server.blank?
    @gate ||= HipChat::Client.new(token, options)
  end

  def message_options(data = nil)
    { notify: notify.present? && Gitlab::Utils.to_boolean(notify), color: message_color(data) }
  end

  def create_message(data)
    object_kind = data[:object_kind]

    case object_kind
    when "push", "tag_push"
      create_push_message(data)
    when "issue"
      create_issue_message(data) unless update?(data)
    when "merge_request"
      create_merge_request_message(data) unless update?(data)
    when "note"
      create_note_message(data)
    when "pipeline"
      create_pipeline_message(data) if should_pipeline_be_notified?(data)
    end
  end

  def render_line(text)
    markdown(text.lines.first.chomp, pipeline: :single_line) if text
  end

  def create_push_message(push)
    ref_type = Gitlab::Git.tag_ref?(push[:ref]) ? 'tag' : 'branch'
    ref = Gitlab::Git.ref_name(push[:ref])

    before = push[:before]
    after = push[:after]

    message = ""
    message << "#{push[:user_name]} "

    if Gitlab::Git.blank_ref?(before)
      message << "pushed new #{ref_type} <a href=\""\
                 "#{project_url}/commits/#{CGI.escape(ref)}\">#{ref}</a>"\
                 " to #{project_link}\n"
    elsif Gitlab::Git.blank_ref?(after)
      message << "removed #{ref_type} <b>#{ref}</b> from <a href=\"#{project.web_url}\">#{project_name}</a> \n"
    else
      message << "pushed to #{ref_type} <a href=\""\
                  "#{project.web_url}/commits/#{CGI.escape(ref)}\">#{ref}</a> "
      message << "of <a href=\"#{project.web_url}\">#{project.full_name.gsub!(/\s/, '')}</a> "
      message << "(<a href=\"#{project.web_url}/compare/#{before}...#{after}\">Compare changes</a>)"

      push[:commits].take(MAX_COMMITS).each do |commit|
        message << "<br /> - #{render_line(commit[:message])} (<a href=\"#{commit[:url]}\">#{commit[:id][0..5]}</a>)"
      end

      if push[:commits].count > MAX_COMMITS
        message << "<br />... #{push[:commits].count - MAX_COMMITS} more commits"
      end
    end

    message
  end

  def markdown(text, options = {})
    return "" unless text

    context = {
      project: project,
      pipeline: :email
    }

    Banzai.render(text, context)

    context.merge!(options)

    html = Banzai.post_process(Banzai.render(text, context), context)
    sanitized_html = sanitize(html, tags: HIPCHAT_ALLOWED_TAGS, attributes: %w[href title alt])

    sanitized_html.truncate(200, separator: ' ', omission: '...')
  end

  def create_issue_message(data)
    user_name = data[:user][:name]

    obj_attr = data[:object_attributes]
    obj_attr = HashWithIndifferentAccess.new(obj_attr)
    title = render_line(obj_attr[:title])
    state = obj_attr[:state]
    issue_iid = obj_attr[:iid]
    issue_url = obj_attr[:url]
    description = obj_attr[:description]

    issue_link = "<a href=\"#{issue_url}\">issue ##{issue_iid}</a>"
    message = "#{user_name} #{state} #{issue_link} in #{project_link}: <b>#{title}</b>"

    message << "<pre>#{markdown(description)}</pre>"

    message
  end

  def create_merge_request_message(data)
    user_name = data[:user][:name]

    obj_attr = data[:object_attributes]
    obj_attr = HashWithIndifferentAccess.new(obj_attr)
    merge_request_id = obj_attr[:iid]
    state = obj_attr[:state]
    description = obj_attr[:description]
    title = render_line(obj_attr[:title])

    merge_request_url = "#{project_url}/merge_requests/#{merge_request_id}"
    merge_request_link = "<a href=\"#{merge_request_url}\">merge request !#{merge_request_id}</a>"
    message = "#{user_name} #{state} #{merge_request_link} in " \
      "#{project_link}: <b>#{title}</b>"

    message << "<pre>#{markdown(description)}</pre>"

    message
  end

  def format_title(title)
    "<b>#{render_line(title)}</b>"
  end

  def create_note_message(data)
    data = HashWithIndifferentAccess.new(data)
    user_name = data[:user][:name]

    obj_attr = HashWithIndifferentAccess.new(data[:object_attributes])
    note = obj_attr[:note]
    note_url = obj_attr[:url]
    noteable_type = obj_attr[:noteable_type]
    commit_id = nil

    case noteable_type
    when "Commit"
      commit_attr = HashWithIndifferentAccess.new(data[:commit])
      commit_id = commit_attr[:id]
      subject_desc = commit_id
      subject_desc = Commit.truncate_sha(subject_desc)
      subject_type = "commit"
      title = format_title(commit_attr[:message])
    when "Issue"
      subj_attr = HashWithIndifferentAccess.new(data[:issue])
      subject_id = subj_attr[:iid]
      subject_desc = "##{subject_id}"
      subject_type = "issue"
      title = format_title(subj_attr[:title])
    when "MergeRequest"
      subj_attr = HashWithIndifferentAccess.new(data[:merge_request])
      subject_id = subj_attr[:iid]
      subject_desc = "!#{subject_id}"
      subject_type = "merge request"
      title = format_title(subj_attr[:title])
    when "Snippet"
      subj_attr = HashWithIndifferentAccess.new(data[:snippet])
      subject_id = subj_attr[:id]
      subject_desc = "##{subject_id}"
      subject_type = "snippet"
      title = format_title(subj_attr[:title])
    end

    subject_html = "<a href=\"#{note_url}\">#{subject_type} #{subject_desc}</a>"
    message = "#{user_name} commented on #{subject_html} in #{project_link}: "
    message << title

    message << "<pre>#{markdown(note, ref: commit_id)}</pre>"

    message
  end

  def create_pipeline_message(data)
    pipeline_attributes = data[:object_attributes]
    pipeline_id = pipeline_attributes[:id]
    ref_type = pipeline_attributes[:tag] ? 'tag' : 'branch'
    ref = pipeline_attributes[:ref]
    user_name = (data[:user] && data[:user][:name]) || 'API'
    status = pipeline_attributes[:status]
    duration = pipeline_attributes[:duration]

    branch_link = "<a href=\"#{project_url}/commits/#{CGI.escape(ref)}\">#{ref}</a>"
    pipeline_url = "<a href=\"#{project_url}/pipelines/#{pipeline_id}\">##{pipeline_id}</a>"

    "#{project_link}: Pipeline #{pipeline_url} of #{branch_link} #{ref_type} by #{user_name} #{humanized_status(status)} in #{duration} second(s)"
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
