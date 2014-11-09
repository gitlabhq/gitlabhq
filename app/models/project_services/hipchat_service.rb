# == Schema Information
#
# Table name: services
#
#  id         :integer          not null, primary key
#  type       :string(255)
#  title      :string(255)
#  project_id :integer          not null
#  created_at :datetime
#  updated_at :datetime
#  active     :boolean          default(FALSE), not null
#  properties :text
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
      { type: 'text', name: 'token',     placeholder: '' },
      { type: 'text', name: 'room',      placeholder: '' },
      { type: 'text', name: 'server',
        placeholder: 'Leave blank for default. https://chat.hipchat.com' }
    ]
  end

  def execute(push_data)
    gate[room].send('GitLab', create_message(push_data))
  end

  private

  def gate
    options = { api_version: 'v2' }
    options[:server_url] = server unless server.nil?
    @gate ||= HipChat::Client.new(token, options)
  end

  def create_message(push)
    ref = push[:ref].gsub("refs/heads/", "")
    before = push[:before]
    after = push[:after]

    message = ""
    message << "#{push[:user_name]} "
    if before =~ /000000/
      message << "pushed new branch <a href=\""\
                 "#{project.web_url}/commits/#{URI.escape(ref)}\">#{ref}</a>"\
                 " to <a href=\"#{project.web_url}\">"\
                 "#{project.name_with_namespace.gsub!(/\s/, "")}</a>\n"
    elsif after =~ /000000/
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
end
