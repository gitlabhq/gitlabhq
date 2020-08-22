Rails.backtrace_cleaner.remove_silencers!

# This allows us to see the proper caller of SQL calls in {development,test}.log
if (Rails.env.development? || Rails.env.test?) && Gitlab.ee?
  Rails.backtrace_cleaner.add_silencer { |line| %r(^ee/lib/gitlab/database/load_balancing).match?(line) }
end

Rails.backtrace_cleaner.add_silencer { |line| !Gitlab::APP_DIRS_PATTERN.match?(line) }
