namespace :gitlab do
  namespace :git do
    desc 'GitLab | Git | Check all repos integrity'
    task fsck: :gitlab_environment do
      failures = []
      Project.find_each(batch_size: 100) do |project|
        begin
          project.repository.fsck

        rescue => e
          failures << "#{project.full_path} on #{project.repository_storage}: #{e}"
        end

        puts "Performed integrity check for #{project.repository.full_path}"
      end

      if failures.empty?
        puts "Done".color(:green)
      else
        puts "The following repositories reported errors:".color(:red)
        failures.each { |f| puts "- #{f}" }
      end
    end
  end
end
