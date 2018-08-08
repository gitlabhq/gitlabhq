namespace :gitlab do
  namespace :quick_actions do
    namespace :test_reports do
      task create_running_pipeline: "gitlab:quick_actions:base:before"
      task finish_last_pipeline: "gitlab:quick_actions:base:before"
      task destroy_pipeline: "gitlab:quick_actions:base:before"

      desc 'GitLab | Quick actions | Test reports | Create a new running pipeline with test reports'
      task :create_running_pipeline, [:project_id, :ref, :junit_file] do |t, args|
        project = Project.find(args[:project_id])
        last_commit = project.repository.commit(args[:ref])

        Ci::Pipeline.transaction do
          pipeline = create_pipeline(User.first, project, args[:ref], last_commit.sha)
          build = create_build(project, pipeline)
          create_test_report(project, build, args[:junit_file])
          project.merge_requests.find_by_source_branch(args[:ref])&.update!(head_pipeline_id: pipeline.id)
        end
      end

      desc 'GitLab | Quick actions | Test reports | Finish the last pipeline'
      task :finish_last_pipeline, [:project_id, :ref] do |t, args|
        project = Project.find(args[:project_id])

        last_pipeline = project.pipelines.where(ref: args[:ref]).last
        last_pipeline.builds.update_all(status: :success)
        last_pipeline.update_status
      end

      desc 'GitLab | Quick actions | Test reports | Destroy pipelines'
      task :destroy_pipeline, [:project_id, :ref] do |t, args|
        project = Project.find(args[:project_id])

        project.pipelines.where(ref: args[:ref]).destroy_all
      end

      def create_pipeline(user, project, ref, sha)
        FactoryBot.create(
          :ci_pipeline,
          :running,
          project: project,
          ref: ref,
          sha: sha,
          user: User.first,
          source: :push)
      end

      def create_build(project, pipeline)
        FactoryBot.create(
          :ci_build,
          :running,
          name: 'rspec',
          stage: 'test',
          project: project,
          pipeline: pipeline)
      end

      def create_test_report(project, build, file)
        FactoryBot.create(
          :ci_job_artifact,
          :junit,
          file: file,
          project: project,
          job: build)
      end
    end
  end
end
