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

class GitlabCiService < CiService
  API_PREFIX = "api/v1"

  prop_accessor :project_url, :token
  validates :project_url,
    presence: true,
    format: { with: /\A#{URI.regexp(%w(http https))}\z/, message: "should be a valid url" }, if: :activated?
  validates :token,
    presence: true,
    format: { with: /\A([A-Za-z0-9]+)\z/ },  if: :activated?

  after_save :compose_service_hook, if: :activated?

  def compose_service_hook
    hook = service_hook || build_service_hook
    hook.url = [project_url, "/build", "?token=#{token}"].join("")
    hook.save
  end

  def supported_events
    %w(push tag_push)
  end

  def execute(data)
    return unless supported_events.include?(data[:object_kind])

    sha = data[:checkout_sha]

    if sha.present?
      file = ci_yaml_file(sha)

      if file && file.data
        data.merge!(ci_yaml_file: file.data)
      end
    end

    service_hook.execute(data)
  end

  def commit_status_path(sha, ref)
    URI::encode(project_url + "/refs/#{ref}/commits/#{sha}/status.json?token=#{token}")
  end

  def get_ci_build(sha, ref)
    @ci_builds ||= {}
    @ci_builds[sha] ||= HTTParty.get(commit_status_path(sha, ref), verify: false)
  end

  def commit_status(sha, ref)
    response = get_ci_build(sha, ref)

    if response.code == 200 and response["status"]
      response["status"]
    else
      :error
    end
  rescue Errno::ECONNREFUSED
    :error
  end

  def fork_registration(new_project, private_token)
    params = {
      id:                  new_project.id,
      name_with_namespace: new_project.name_with_namespace,
      path_with_namespace: new_project.path_with_namespace,
      web_url:             new_project.web_url,
      default_branch:      new_project.default_branch,
      ssh_url_to_repo:     new_project.ssh_url_to_repo
    }

    HTTParty.post(
      fork_registration_path,
      body: {
        project_id: project.id,
        project_token: token,
        private_token: private_token,
        data: params },
      verify: false
    )
  end

  def commit_coverage(sha, ref)
    response = get_ci_build(sha, ref)

    if response.code == 200 and response["coverage"]
      response["coverage"]
    end
  rescue Errno::ECONNREFUSED
    nil
  end

  def build_page(sha, ref)
    URI::encode(project_url + "/refs/#{ref}/commits/#{sha}")
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
      { type: 'text', name: 'project_url', placeholder: 'http://ci.gitlabhq.com/projects/3' }
    ]
  end

  private

  def ci_yaml_file(sha)
    repository.blob_at(sha, '.gitlab-ci.yml')
  end

  def fork_registration_path
    project_url.sub(/projects\/\d*/, "#{API_PREFIX}/forks")
  end

  def repository
    project.repository
  end
end
