# == Schema Information
#
# Table name: services
#
#  id                    :integer          not null, primary key
#  type                  :string(255)
#  title                 :string(255)
#  project_id            :integer
#  created_at            :datetime
#  updated_at            :datetime
#  active                :boolean          default(FALSE), not null
#  properties            :text
#  template              :boolean          default(FALSE)
#  push_events           :boolean          default(TRUE)
#  issues_events         :boolean          default(TRUE)
#  merge_requests_events :boolean          default(TRUE)
#  tag_push_events       :boolean          default(TRUE)
#  note_events           :boolean          default(TRUE), not null
#

class LetschatService < Service
  MAX_COMMITS = 3

  prop_accessor :token, :room, :server, :notify, :color, :api_version
  validates :token, presence: true, if: :activated?

  def title
    'LetsChat'
  end

  def description
    'Private group chat and IM'
  end

  def to_param
    'letschat'
  end

  def fields
    [
      { type: 'text', name: 'token',     placeholder: 'Account token' },
      { type: 'text', name: 'room',      placeholder: 'Room ID' },
      { type: 'text', name: 'server',    placeholder: 'Server URL' }
    ]
  end

  def supported_events
    %w(push issue merge_request note tag_push)
  end

  def execute(data)
    return unless supported_events.include?(data[:object_kind])
    message = create_message(data)
    return unless message.present?

    HTTParty.post(
      server+'/messages',
      query: {
        "text" => message,
        "room" => room 
      },
      headers: { "Authorization" => "Bearer " + token }
    )
  end

  private

  def message_options
    { notify: notify.present? && notify == '1', color: color || 'yellow' }
  end

  def create_message(data)
    object_kind = data[:object_kind]

    message = \
      case object_kind
      when "push", "tag_push"
        create_push_message(data)
      when "issue"
        create_issue_message(data) unless is_update?(data)
      when "merge_request"
        create_merge_request_message(data) unless is_update?(data)
      when "note"
        create_note_message(data)
      end
  end

  def create_push_message(push)
    ref_type = Gitlab::Git.tag_ref?(push[:ref]) ? 'tag' : 'branch'
    ref = Gitlab::Git.ref_name(push[:ref])

    before = push[:before]
    after = push[:after]

    message = "[#{project_name}]"
    message << " #{push[:user_name]} "
    if Gitlab::Git.blank_ref?(before)
      message << "pushed new #{ref_type} "\
                 "#{project_url}/commits/#{URI.escape(ref)} #{ref}\n"
    elsif Gitlab::Git.blank_ref?(after)
      message << "removed #{ref_type} #{ref}\n"
    else
      message << "pushed to #{ref_type} "\
                  "#{project.web_url}/commits/#{URI.escape(ref)} #{ref} "
      message << "(#{project.web_url}/compare/#{before}...#{after} Compare changes)"

      push[:commits].take(MAX_COMMITS).each do |commit|
        message << " - #{commit[:message].lines.first} (#{commit[:url]} #{commit[:id][0..5]})"
      end

      if push[:commits].count > MAX_COMMITS
        message << "... #{push[:commits].count - MAX_COMMITS} more commits"
      end
    end

    message
  end

  def format_body(body)
    if body
      body = body.truncate(200, separator: ' ', omission: '...')
    end

    "#{body}"
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

    message = "[#{project_name}] #{user_name} #{state} issue ##{issue_iid} #{issue_url}"
    message << "\ntitle:#{title}"

    if description
      description = format_body(description)
      message << "\n"+description
    end

    message
  end

  def create_merge_request_message(data)
    user_name = data[:user][:name]

    obj_attr = data[:object_attributes]
    obj_attr = HashWithIndifferentAccess.new(obj_attr)
    merge_request_id = obj_attr[:iid]
    source_branch = obj_attr[:source_branch]
    target_branch = obj_attr[:target_branch]
    state = obj_attr[:state]
    description = obj_attr[:description]
    title = obj_attr[:title]

    merge_request_url = "#{project_url}/merge_requests/#{merge_request_id}"
    merge_request_num = "merge request ##{merge_request_id}"
    message = "[#{project_name}] #{user_name} #{state} #{merge_request_num} #{merge_request_url}"
    message << "\ntitle:#{title}"

    if description
      description = format_body(description)
      message << "\n"+description
    end

    message
  end

  def format_title(title)
    title.lines.first.chomp
  end

  def create_note_message(data)
    data = HashWithIndifferentAccess.new(data)
    user_name = data[:user][:name]

    repo_attr = HashWithIndifferentAccess.new(data[:repository])

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
      subject_desc = "##{subject_id}"
      subject_type = "merge request"
      title = format_title(subj_attr[:title])
    when "Snippet"
      subj_attr = HashWithIndifferentAccess.new(data[:snippet])
      subject_id = subj_attr[:id]
      subject_desc = "##{subject_id}"
      subject_type = "snippet"
      title = format_title(subj_attr[:title])
    end

    subject_html = "#{subject_type} #{subject_desc} #{note_url}"
    message = "[#{project_name}] #{user_name} commented on #{subject_html}"
    message << "\ntitle:"+title+""

    if note
      note = format_body(note)
      message << "\n"+note
    end

    message
  end

  def project_name
    project.name_with_namespace.gsub(/\s/, '')
  end

  def project_url
    project.web_url
  end

  def project_link
    "#{project_name} ( #{project_url} )"
  end

  def is_update?(data)
    data[:object_attributes][:action] == 'update'
  end
end
