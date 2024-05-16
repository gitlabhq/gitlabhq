# frozen_string_literal: true

# https://github.com/rails/rails/pull/46656 disables IRB auto-completion
# by default in Rails 7.1.
if Gem::Version.new(Rails.gem_version) >= Gem::Version.new('7.1') # rubocop:disable Style/GuardClause -- This is easier to read
  raise 'New version of Rails detected, please remove USE_AUTOCOMPLETE override'
end

if Gitlab::Runtime.console?
  # Stop irb from writing a history file by default.
  module IrbNoHistory
    def init_config(*)
      super

      IRB.conf[:SAVE_HISTORY] = false

      init_autocomplete
    end

    def init_autocomplete
      return unless Rails.env.production?

      # IRB_USE_AUTOCOMPLETE was added in https://github.com/ruby/irb/pull/469
      IRB.conf[:USE_AUTOCOMPLETE] = ENV.fetch("IRB_USE_AUTOCOMPLETE", "false") == "true"
    end
  end

  IRB.singleton_class.prepend(IrbNoHistory)
end
