namespace :gitlab do
  namespace :dev do
    desc 'Checks if the branch would apply cleanly to EE'
    task :ee_compat_check, [:branch] => :environment do |_, args|
      opts =
        if ENV['CI']
          {
            ce_project_url: ENV['CI_PROJECT_URL'],
            branch: ENV['CI_COMMIT_REF_NAME'],
            job_id: ENV['CI_JOB_ID']
          }
        else
          unless args[:branch]
            puts "Must specify a branch as an argument".color(:red)
            exit 1
          end

          args
        end

      if File.basename(Rails.root) == 'gitlab-ee'
        puts "Skipping EE projects"
        exit 0
      elsif Gitlab::EeCompatCheck.new(opts || {}).check
        exit 0
      else
        exit 1
      end
    end
  end
end
