# frozen_string_literal: true

if Gitlab::Runtime.console?
  require "irb"

  # Stop irb from writing a history file by default.
  module IrbNoHistory
    def init_config(*)
      super

      IRB.conf[:SAVE_HISTORY] = false

      init_autocomplete
    end

    def init_autocomplete
      return if ::Gitlab.next_rails?
      return unless Rails.env.production?

      # IRB_USE_AUTOCOMPLETE was added in https://github.com/ruby/irb/pull/469
      IRB.conf[:USE_AUTOCOMPLETE] = ENV.fetch("IRB_USE_AUTOCOMPLETE", "false") == "true"
    end
  end

  IRB.singleton_class.prepend(IrbNoHistory)
end
