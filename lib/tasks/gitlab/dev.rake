namespace :gitlab do
  namespace :dev do
    desc 'Checks if the branch would apply cleanly to EE'
    task ee_compat_check: :environment do
      return if defined?(Gitlab::License)
      return unless ENV['CI']

      success =
        Gitlab::EeCompatCheck.new(
          branch: ENV['CI_BUILD_REF_NAME'],
          check_dir: File.expand_path('ee-compat-check', __dir__),
          ce_repo: ENV['CI_BUILD_REPO']
        ).check

      if success
        exit 0
      else
        exit 1
      end
    end
  end
end
