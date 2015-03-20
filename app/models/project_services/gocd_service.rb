# == Schema Information
#
# Table name: services
#
#  id         :integer          not null, primary key
#  type       :string(255)
#  title      :string(255)
#  project_id :integer
#  created_at :datetime
#  updated_at :datetime
#  active     :boolean          default(FALSE), not null
#  properties :text
#  template   :boolean          default(FALSE)
#
class GocdService < Service
  include HTTParty

  prop_accessor :gocd_url, :username, :password, :restrict_to_branch

  validates :gocd_url, presence: true, if: :activated?

  def execute(push)
    user = push[:user_name]
    branch = push[:ref].gsub('refs/heads/', '')

    branch_restriction = restrict_to_branch.to_s

    # check the branch restriction is poplulated and branch is not included
    if branch_restriction.length > 0 && branch_restriction.index(branch) == nil
      return
    end

    notify()
  end

  def notify_url
    "#{gocd_url}/api/material/notify/git"
  end

  def notify()
    url = notify_url()
    #body = "repository_url=#{Gitlab.config.gitlab.url}/#{project.path_with_namespace}"
    body = "repository_url=#{Gitlab.config.gitlab.user}@#{Gitlab.config.gitlab.ssh_host}:#{project.path_with_namespace}.git"

    if username.blank? && password.blank?
      response = HTTParty.post(url, body: body, verify: false)
    else
      auth = {
          username: username,
          password: password,
      }
      response = HTTParty.post(url, body: body, verify: false, basic_auth: auth)
    end

    if response.code == 200 && response['status']
      response['status']
    else
      :error
    end
  end

  #def build_page(sha)
  #  # No suitable page so we return the top level
  #  return gocd_url
  #end

  #def commit_status(sha)
  #  notify()
  #end

  def check_commit(message, push_msg)
    echo 'Check commit called in gocd'
  end

  def title
    'Go CD'
  end

  def description
    'Continuous integration and deployments'
  end

  def to_param
    'gocd'
  end

  def fields
    [
      { type: 'text',
        name: 'username',
        placeholder: 'Go CD login username' },

      { type: 'password',
        name: 'password',
        placeholder: 'Go CD login password' },

      { type: 'text',
        name: 'gocd_url',
        placeholder: 'http://gocd.example.com:8153/go'},
      {
        type: 'text',
        name: 'restrict_to_branch',
        placeholder: 'Comma-separated list of branches which will be
automatically inspected. Leave blank to include all branches.'
      }
    ]
  end
end
