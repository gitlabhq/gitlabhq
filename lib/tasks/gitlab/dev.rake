namespace :gitlab do
  namespace :dev do
    desc 'Checks if the branch would apply cleanly to EE'
    task :ee_compat_check, [:branch] => :environment do |_, args|
      opts =
        if ENV['CI']
          {
            # We don't use CI_REPOSITORY_URL since it includes `gitlab-ci-token:xxxxxxxxxxxxxxxxxxxx@`
            # which is confusing in the steps suggested in the job's output.
            ce_repo: "#{ENV['CI_PROJECT_URL']}.git",
            branch: ENV['CI_COMMIT_REF_NAME']
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
