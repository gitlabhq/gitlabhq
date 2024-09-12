# frozen_string_literal: true

namespace :gitlab do
  namespace :artifacts do
    desc "GitLab | Artifacts | Expire artifacts without an expiration"
    task update_missing_expiration: :environment do
      # Get Group or Project path from arguments
      group_path = ENV['GROUP_PATH']
      project_path = ENV['PROJECT_PATH']

      dry_run = true
      dry_run = Gitlab::Utils.to_boolean(ENV['DRY_RUN']) if ENV['DRY_RUN']

      if dry_run
        puts "Dry run, no changes will be made."
        puts "To expire artifacts run using DRY_RUN=false."
      else
        puts "Expiring artifacts"
      end

      projects = nil

      if group_path.present?
        projects = Group.find_by_full_path(group_path)&.all_projects
      elsif project_path.present?
        project = Project.find_by_full_path(project_path)
        projects = [project] if project
      else
        puts 'Error: GROUP_PATH or PROJECT_PATH required'
        exit 1
      end

      if projects.nil?
        puts 'Error: Invalid path'
        exit 1
      end

      projects.each do |project|
        puts "Working on project: #{project.name}"
        project.builds.each_batch(of: 1000) do |builds|
          builds.with_downloadable_artifacts.select { |b| b.artifacts_expire_at.nil? }.each do |build|
            build.job_artifacts.downloadable.each do |artifact|
              puts "Processing project #{project.name}, build #{build.id}, artifact #{artifact.id}"
              artifact.update(expire_at: Time.current) unless dry_run
              puts "Artifact #{artifact.id} expired #{artifact.expire_at}" unless dry_run
            end
            build.update(artifacts_expire_at: Time.current) unless dry_run
            puts "Build #{build.id} expired #{build.artifacts_expire_at}" unless dry_run
          end
        end
      end
    end
  end
end
