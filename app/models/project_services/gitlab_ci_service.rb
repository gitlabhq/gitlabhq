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

# TODO(ayufan): The GitLabCiService is deprecated and the type should be removed when the database entries are removed
class GitlabCiService < CiService
<<<<<<< HEAD
  # We override the active accessor to always make GitLabCiService disabled
  # Otherwise the GitLabCiService can be picked, but should never be since it's deprecated
  def active
    false
=======
  include Gitlab::Application.routes.url_helpers

  after_save :compose_service_hook, if: :activated?

  def compose_service_hook
    hook = service_hook || build_service_hook
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

  def fork_registration(new_project, current_user)
    params = OpenStruct.new({
      id:                  new_project.id,
      name_with_namespace: new_project.name_with_namespace,
      path_with_namespace: new_project.path_with_namespace,
      web_url:             new_project.web_url,
      default_branch:      new_project.default_branch,
      ssh_url_to_repo:     new_project.ssh_url_to_repo
    })

    ci_project = Ci::Project.find_by!(gitlab_id: project.id)
    
    Ci::CreateProjectService.new.execute(
      current_user,
      params,
      ci_project
    )
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
>>>>>>> origin/8-0-stable
  end
end
