require './spec/support/sidekiq'

class Gitlab::Seeder::Environments
  def initialize(project)
    @project = project
  end

  def seed!
    @project.create_mock_deployment_service!(active: true)
    @project.create_mock_monitoring_service!(active: true)

    create_master_deployments!('production')
    create_master_deployments!('staging')
    create_merge_request_review_deployments!
  end

  private

  def create_master_deployments!(name)
    @project.repository.commits('master', limit: 4).map do |commit|
      create_deployment!(
        @project,
        name,
        'master',
        commit.id
      )
    end
  end

  def create_merge_request_review_deployments!
    @project
      .merge_requests
      .select { |mr| mr.source_branch.match(/\p{Alnum}+/) }
      .sample(4)
      .each do |merge_request|
      next unless merge_request.diff_head_sha

      create_deployment!(
        merge_request.source_project,
        "review/#{merge_request.source_branch.gsub(/[^a-zA-Z0-9]/, '')}",
        merge_request.source_branch,
        merge_request.diff_head_sha
      )
    end
  end

  def create_deployment!(project, name, ref, sha)
    environment = find_or_create_environment!(project, name)
    environment.deployments.create!(
      project: project,
      ref: ref,
      sha: sha,
      tag: false,
      deployable: find_deployable(project, name)
    )
  end

  def find_or_create_environment!(project, name)
    project.environments.find_or_create_by!(name: name).tap do |environment|
      environment.update(external_url: "https://google.com/#{name}")
    end
  end

  def find_deployable(project, environment)
    project.builds.where(environment: environment).sample
  end
end

Gitlab::Seeder.quiet do
  Project.all.sample(5).each do |project|
    project_environments = Gitlab::Seeder::Environments.new(project)
    project_environments.seed!
  end
end
