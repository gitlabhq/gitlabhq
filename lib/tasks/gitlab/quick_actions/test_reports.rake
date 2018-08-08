namespace :gitlab do
  namespace :quick_actions do
    namespace :test_reports do
      task create_running_pipeline: "gitlab:quick_actions:base:before"
      task finish_last_pipeline: "gitlab:quick_actions:base:before"
      task destroy_pipeline: "gitlab:quick_actions:base:before"

      # raise 'Unknown result_pattern' unless %w[pass failed-1 failed-2 failed-3 corrupted].include?(args[:rspec_pattern])
      # raise 'Unknown result_pattern' unless %w[pass failed-1 failed-2 failed-3].include?(args[:ant_pattern])
      # artifacts_cache_file

      desc 'GitLab | Quick actions | Create a new running pipeline with test reports'
      task :create_running_pipeline, [:project_id, :ref, :rspec_file] do |t, args|
        project = Project.find(args[:project_id])
        last_commit = project.repository.commit(args[:ref])

        Ci::Pipeline.transaction do
          pipeline = FactoryBot.create(:ci_pipeline, :running, project: project, ref: args[:ref], sha: last_commit)
          build = FactoryBot.create(:ci_build, :running, name: 'rspec', stage: 'test', project: project)
          FactoryBot.create(:ci_job_artifact, :archive, project: project, job: build)
          project.merge_requests.find_by_source_branch(args[:ref])&.update!(head_pipeline_id: pipeline.id)
          binding.pry
        end
      end

      desc 'GitLab | Quick actions | Finish the last pipeline'
      task :finish_last_pipeline, [:project_id, :ref] do |t, args|
        project = Project.find(args[:project_id])

        last_pipeline = project.pipelines.where(ref: args[:ref]).last
        last_pipeline.builds.update_all(status: :success)
        last_pipeline.update_status
      end

      desc 'GitLab | Quick actions | Destroy pipelines'
      task :destroy_pipeline, [:project_id, :ref] do |t, args|
        project = Project.find(args[:project_id])

        project.pipelines.where(ref: args[:ref]).destroy_all
      end
    end
  end
end
