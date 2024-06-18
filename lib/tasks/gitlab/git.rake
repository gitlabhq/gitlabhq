# frozen_string_literal: true

namespace :gitlab do
  namespace :git do
    desc 'GitLab | Git | Check all repos integrity'
    task fsck: :gitlab_environment do
      failures = []
      Project.find_each(batch_size: 100) do |project|
        begin
          project.repository.fsck

        rescue StandardError => e
          failures << "#{project.full_path} on #{project.repository_storage}: #{e}"
        end

        puts "Performed integrity check for #{project.repository.full_path}"
      end

      if failures.empty?
        puts Rainbow("Done").green
      else
        puts Rainbow("The following repositories reported errors:").red
        failures.each { |f| puts "- #{f}" }
      end
    end

    # Example for all projects:
    #
    #   $ bin/rake gitlab:git:checksum_projects
    #   1,cfa3f06ba235c13df0bb28e079bcea62c5848af2
    #   2,
    #   3,3f3fb58a8106230e3a6c6b48adc2712fb3b6ef87
    #   4,0000000000000000000000000000000000000000
    #
    # Example with a list of project IDs:
    #
    #   $ CHECKSUM_PROJECT_IDS="1,3" bin/rake gitlab:git:checksum_projects
    #   1,cfa3f06ba235c13df0bb28e079bcea62c5848af2
    #   3,3f3fb58a8106230e3a6c6b48adc2712fb3b6ef87
    #
    # - If a repository does not exist, the project ID is output with a blank checksum
    # - If a repository exists but is empty, the output checksum is `0000000000000000000000000000000000000000`
    # - If given specific IDs, projects which do not exist are skipped
    desc 'GitLab | Git | Generate checksum of project repository refs'
    task checksum_projects: :environment do
      project_ids = ENV['CHECKSUM_PROJECT_IDS']&.split(',')
      relation = Project
      relation = relation.where(id: project_ids) if project_ids.present?

      relation.find_each(batch_size: 100) do |project|
        next unless project.repo_exists?

        result = project.repository.checksum
      rescue StandardError => e
        result = "Ignored error: #{e.message}".squish.truncate(255)
      ensure
        puts "#{project.id},#{result}"
      end
    end
  end
end
