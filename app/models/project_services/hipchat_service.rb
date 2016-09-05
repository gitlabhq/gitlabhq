class HipchatService < Service
  MAX_COMMITS = 3

  prop_accessor :token, :room, :server, :notify, :color, :api_version
  boolean_accessor :notify_only_broken_builds
  validates :token, presence: true, if: :activated?

  def initialize_properties
    if properties.nil?
      self.properties = {}
      self.notify_only_broken_builds = true
    end
  end

  def title
    'HipChat'
  end

  def description
    'Private group chat and IM'
  end

  def to_param
    'hipchat'
  end

  def fields
    [
      { type: 'text', name: 'token',     placeholder: 'Room token' },
      { type: 'text', name: 'room',      placeholder: 'Room name or ID' },
      { type: 'checkbox', name: 'notify' },
      { type: 'select', name: 'color', choices: ['yellow', 'red', 'green', 'purple', 'gray', 'random'] },
      { type: 'text', name: 'api_version',
        placeholder: 'Leave blank for default (v2)' },
      { type: 'text', name: 'server',
        placeholder: 'Leave blank for default. https://hipchat.example.com' },
      { type: 'checkbox', name: 'notify_only_broken_builds' },
    ]
  end

  def supported_events
    %w(push issue confidential_issue merge_request note tag_push build)
  end

  def execute(data)
    return unless supported_events.include?(data[:object_kind])
    message = create_message(data)
    return unless message.present?
    gate[room].send('GitLab', message, message_options(data))
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
    { notify: notify.present? && notify == '1', color: message_color(data) }
  end

  def create_message(data)
    object_kind = data[:object_kind]

    case object_kind
    when "push", "tag_push"
      create_push_message(data)
    when "issue"
      create_issue_message(data) unless is_update?(data)
    when "merge_request"
      create_merge_request_message(data) unless is_update?(data)
    when "note"
      create_note_message(data)
    when "build"
      create_build_message(data) if should_build_be_notified?(data)
    end
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
      message << "of <a href=\"#{project.web_url}\">#{project.name_with_namespace.gsub!(/\s/, '')}</a> "
      message << "(<a href=\"#{project.web_url}/compare/#{before}...#{after}\">Compare changes</a>)"

      push[:commits].take(MAX_COMMITS).each do |commit|
        message << "<br /> - #{commit[:message].lines.first} (<a href=\"#{commit[:url]}\">#{commit[:id][0..5]}</a>)"
      end

      if push[:commits].count > MAX_COMMITS
        message << "<br />... #{push[:commits].count - MAX_COMMITS} more commits"
      end
    end

    message
  end

  def format_body(body)
    if body
      body = body.truncate(200, separator: ' ', omission: '...')
    end

    "<pre>#{body}</pre>"
  end

  def create_issue_message(data)
    user_name = data[:user][:name]

    obj_attr = data[:object_attributes]
    obj_attr = HashWithIndifferentAccess.new(obj_attr)
    title = obj_attr[:title]
    state = obj_attr[:state]
    issue_iid = obj_attr[:iid]
    issue_url = obj_attr[:url]
    description = obj_attr[:description]

    issue_link = "<a href=\"#{issue_url}\">issue ##{issue_iid}</a>"
    message = "#{user_name} #{state} #{issue_link} in #{project_link}: <b>#{title}</b>"

    if description
      description = format_body(description)
      message << description
    end

    message
  end

  def create_merge_request_message(data)
    user_name = data[:user][:name]

    obj_attr = data[:object_attributes]
    obj_attr = HashWithIndifferentAccess.new(obj_attr)
    merge_request_iid = obj_attr[:iid]
    state = obj_attr[:state]
    description = obj_attr[:description]
    title = obj_attr[:title]
    action = obj_attr[:action]

    state_or_action_text = (action == 'approved') ? action : state

    merge_request_url = "#{project_url}/merge_requests/#{merge_request_iid}"
    merge_request_link = "<a href=\"#{merge_request_url}\">merge request !#{merge_request_iid}</a>"
    message = "#{user_name} #{state_or_action_text} #{merge_request_link} in " \
      "#{project_link}: <b>#{title}</b>"

    if description
      description = format_body(description)
      message << description
    end

    message
  end

  def format_title(title)
    "<b>" + title.lines.first.chomp + "</b>"
  end

  def create_note_message(data)
    data = HashWithIndifferentAccess.new(data)
    user_name = data[:user][:name]

    obj_attr = HashWithIndifferentAccess.new(data[:object_attributes])
    note = obj_attr[:note]
    note_url = obj_attr[:url]
    noteable_type = obj_attr[:noteable_type]

    case noteable_type
    when "Commit"
      commit_attr = HashWithIndifferentAccess.new(data[:commit])
      subject_desc = commit_attr[:id]
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

    if note
      note = format_body(note)
      message << note
    end

    message
  end

  def create_build_message(data)
    ref_type = data[:tag] ? 'tag' : 'branch'
    ref = data[:ref]
    sha = data[:sha]
    user_name = data[:commit][:author_name]
    status = data[:commit][:status]
    duration = data[:commit][:duration]

    branch_link = "<a href=\"#{project_url}/commits/#{CGI.escape(ref)}\">#{ref}</a>"
    commit_link = "<a href=\"#{project_url}/commit/#{CGI.escape(sha)}/builds\">#{Commit.truncate_sha(sha)}</a>"

    "#{project_link}: Commit #{commit_link} of #{branch_link} #{ref_type} by #{user_name} #{humanized_status(status)} in #{duration} second(s)"
  end

  def message_color(data)
    build_status_color(data) || color || 'yellow'
  end

  def build_status_color(data)
    return unless data && data[:object_kind] == 'build'

    case data[:commit][:status]
    when 'success'
      'green'
    else
      'red'
    end
  end

  def project_name
    project.name_with_namespace.gsub(/\s/, '')
  end

  def project_url
    project.web_url
  end

  def project_link
    "<a href=\"#{project_url}\">#{project_name}</a>"
  end

  def is_update?(data)
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

  def should_build_be_notified?(data)
    case data[:commit][:status]
    when 'success'
      !notify_only_broken_builds?
    when 'failed'
      true
    else
      false
    end
  end
end
