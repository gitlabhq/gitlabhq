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
#

class HipchatService < Service
  MAX_COMMITS = 3

  prop_accessor :token, :room, :server
  validates :token, presence: true, if: :activated?

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
      { type: 'text', name: 'server',
        placeholder: 'Leave blank for default. https://hipchat.example.com' }
    ]
  end

  def supported_events
    %w(push issue merge_request)
  end

  def execute(data)
    return unless supported_events.include?(data[:object_kind])

    gate[room].send('GitLab', create_message(data))
  end

  private

  def gate
    options = { api_version: 'v2' }
    options[:server_url] = server unless server.blank?
    @gate ||= HipChat::Client.new(token, options)
  end

  def create_message(data)
    object_kind = data[:object_kind]

    message = \
      case object_kind
      when "push"
        create_push_message(data)
      when "issue"
        create_issue_message(data) unless is_update?(data)
      when "merge_request"
        create_merge_request_message(data) unless is_update?(data)
      end
  end

  def create_push_message(push)
    ref = push[:ref].gsub("refs/heads/", "")
    before = push[:before]
    after = push[:after]

    message = ""
    message << "#{push[:user_name]} "
    if before.include?('000000')
      message << "pushed new branch <a href=\""\
                 "#{project_url}/commits/#{URI.escape(ref)}\">#{ref}</a>"\
                 " to <a href=\"#{project_url}\">"\
                 "#{project_url}</a>\n"
    elsif after.include?('000000')
      message << "removed branch #{ref} from <a href=\"#{project.web_url}\">#{project.name_with_namespace.gsub!(/\s/,'')}</a> \n"
    else
      message << "pushed to branch <a href=\""\
                  "#{project.web_url}/commits/#{URI.escape(ref)}\">#{ref}</a> "
      message << "of <a href=\"#{project.web_url}\">#{project.name_with_namespace.gsub!(/\s/,'')}</a> "
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

  def create_issue_message(data)
    username = data[:user][:username]

    obj_attr = data[:object_attributes]
    obj_attr = HashWithIndifferentAccess.new(obj_attr)
    title = obj_attr[:title]
    state = obj_attr[:state]
    issue_iid = obj_attr[:iid]
    issue_url = obj_attr[:url]
    description = obj_attr[:description]

    issue_link = "<a href=\"#{issue_url}\">##{issue_iid}</a>"
    message = "#{username} #{state} issue #{issue_link} in #{project_link}: <b>#{title}</b>"

    if description
      description = description.truncate(200, separator: ' ', omission: '...')
      message << "<pre>#{description}</pre>"
    end

    message
  end

  def create_merge_request_message(data)
    username = data[:user][:username]

    obj_attr = data[:object_attributes]
    obj_attr = HashWithIndifferentAccess.new(obj_attr)
    merge_request_id = obj_attr[:iid]
    source_branch = obj_attr[:source_branch]
    target_branch = obj_attr[:target_branch]
    state = obj_attr[:state]
    description = obj_attr[:description]
    title = obj_attr[:title]

    merge_request_url = "#{project_url}/merge_requests/#{merge_request_id}"
    merge_request_link = "<a href=\"#{merge_request_url}\">##{merge_request_id}</a>"
    message = "#{username} #{state} merge request #{merge_request_link} in " \
      "#{project_link}: <b>#{title}</b>"

    if description
      description = description.truncate(200, separator: ' ', omission: '...')
      message << "<pre>#{description}</pre>"
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
    "<a href=\"#{project_url}\">#{project_name}</a>"
  end

  def is_update?(data)
    data[:object_attributes][:action] == 'update'
  end
end
