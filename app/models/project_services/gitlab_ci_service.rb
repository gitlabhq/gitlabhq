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

class GitlabCiService < Service
  attr_accessible :project_url

  validates :project_url, presence: true, if: :activated?
  validates :token, presence: true, if: :activated?

  delegate :execute, to: :service_hook, prefix: nil

  after_save :compose_service_hook, if: :activated?

  def compose_service_hook
    hook = service_hook || build_service_hook
    hook.url = [project_url, "/build", "?token=#{token}"].join("")
    hook.save
  end

  def commit_status_path sha
    project_url + "/builds/#{sha}/status.json?token=#{token}"
  end

  def commit_status sha
    response = HTTParty.get(commit_status_path(sha), verify: false)

    if response.code == 200 and response["status"]
      response["status"]
    else
      :error
    end
  end

  def build_page sha
    project_url + "/builds/#{sha}"
  end

  def builds_path
    project_url + "?ref=" + project.default_branch
  end

  def status_img_path
    project_url + "/status.png?ref=" + project.default_branch
  end

  def title
    'GitLab CI'
  end

  def description
    'Continuous integration server from GitLab'
  end

  def to_param
    'gitlab_ci'
  end

  def fields
    [
      { type: 'text', name: 'token', placeholder: 'GitLab CI project specific token' },
      { type: 'text', name: 'project_url', placeholder: 'http://ci.gitlabhq.com/projects/3'}
    ]
  end
end
