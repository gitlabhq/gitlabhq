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
  include Gitlab::Application.routes.url_helpers

  after_save :compose_service_hook, if: :activated?
  after_save :ensure_gitlab_ci_project, if: :activated?

  def compose_service_hook
    hook = service_hook || build_service_hook
    hook.save
  end

  def ensure_gitlab_ci_project
    project.ensure_gitlab_ci_project
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

    ci_project = Ci::Project.find_by(gitlab_id: project.id)
    if ci_project
      Ci::CreateCommitService.new.execute(ci_project, data)
    end
  end

  def token
    if project.gitlab_ci_project.present?
      project.gitlab_ci_project.token
    end
  end

  def get_ci_commit(sha, ref)
    Ci::Project.find(project.gitlab_ci_project).commits.find_by_sha_and_ref!(sha, ref)
  end

  def commit_status(sha, ref)
    get_ci_commit(sha, ref).status
  rescue ActiveRecord::RecordNotFound
    :error
  end

  def commit_coverage(sha, ref)
    get_ci_commit(sha, ref).coverage
  rescue ActiveRecord::RecordNotFound
    :error
  end

  def build_page(sha, ref)
    if project.gitlab_ci_project.present?
      ci_project_ref_commits_url(project.gitlab_ci_project, ref, sha)
    end
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
    []
  end

  private

  def ci_yaml_file(sha)
    repository.blob_at(sha, '.gitlab-ci.yml')
  end

  def repository
    project.repository
  end
end
