# == Schema Information
#
# Table name: services
#
#  id          :integer          not null, primary key
#  type        :string(255)
#  title       :string(255)
#  token       :string(255)
#  project_id  :integer          not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  active      :boolean          default(FALSE), not null
#  project_url :string(255)
#  subdomain   :string(255)
#  room        :string(255)
#

class HipchatService < Service
  attr_accessible :room

  validates :token, presence: true, if: :activated?

  def title
    'Hipchat'
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
      { type: 'text', name: 'room',      placeholder: '' }
    ]
  end

  def execute(push_data)
    gate[room].send('GitLab', create_message(push_data))
  end

  private

  def gate
    @gate ||= HipChat::Client.new(token)
  end

  def create_message(push)
    ref = push[:ref].gsub("refs/heads/", "")
    before = push[:before]
    after = push[:after]

    message = ""
    message << "#{push[:user_name]} "
    if before =~ /000000/
      message << "pushed new branch <a href=\"#{project.web_url}/commits/#{ref}\">#{ref}</a> to <a href=\"#{project.web_url}\">#{project.name_with_namespace.gsub!(/\s/,'')}</a>\n"
    elsif after =~ /000000/
      message << "removed branch #{ref} from <a href=\"#{project.web_url}\">#{project.name_with_namespace.gsub!(/\s/,'')}</a> \n"
    else
      message << "pushed to branch <a href=\"#{project.web_url}/commits/#{ref}\">#{ref}</a> "
      message << "of <a href=\"#{project.web_url}\">#{project.name_with_namespace.gsub!(/\s/,'')}</a> "
      message << "(<a href=\"#{project.web_url}/compare/#{before}...#{after}\">Compare changes</a>)"
      for commit in push[:commits] do
        message << "<br /> - #{commit[:message]} (<a href=\"#{commit[:url]}\">#{commit[:id][0..5]}</a>)"
      end
    end

    message
  end
end
