# frozen_string_literal: true

namespace :gitlab do
  desc "GitLab | Refresh build artifacts size project statistics for given project IDs"

  BUILD_ARTIFACTS_SIZE_REFRESH_ENQUEUE_BATCH_SIZE = 500

  task :refresh_project_statistics_build_artifacts_size, [:project_ids] => :environment do |_t, args|
    project_ids = []
    project_ids = $stdin.read.split unless $stdin.tty?
    project_ids = args.project_ids.to_s.split unless project_ids.any?

    if project_ids.any?
      project_ids.in_groups_of(BUILD_ARTIFACTS_SIZE_REFRESH_ENQUEUE_BATCH_SIZE) do |ids|
        projects = Project.where(id: ids)
        Projects::BuildArtifactsSizeRefresh.enqueue_refresh(projects)
      end
      puts 'Done.'.green
    else
      puts 'Please provide a string of space-separated project IDs as the argument or through the STDIN'.red
    end
  end
end
