Rails.backtrace_cleaner.remove_silencers!
Rails.backtrace_cleaner.add_silencer { |line| line !~ Gitlab::APP_DIRS_PATTERN }
