namespace :gitlab do
  namespace :dev do
    desc 'Checks if the branch would apply cleanly to EE'
    task :ee_compat_check, [:branch] => :environment do |_, args|
      opts =
        if ENV['CI']
          {
            branch: ENV['CI_BUILD_REF_NAME'],
            ce_repo: ENV['CI_BUILD_REPO']
          }
        else
          unless args[:branch]
            puts "Must specify a branch as an argument".color(:red)
            exit 1
          end
          args
        end

      if Gitlab::EeCompatCheck.new(opts || {}).check
        exit 0
      else
        exit 1
      end
    end
  end
end
