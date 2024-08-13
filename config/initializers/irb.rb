# frozen_string_literal: true

if Gitlab::Runtime.console?
  # Stop irb from writing a history file by default.
  module IrbNoHistory
    def init_config(*)
      super

      IRB.conf[:SAVE_HISTORY] = false

      init_autocomplete
    end

    unless ::Gitlab.next_rails?
      def init_autocomplete
        return unless Rails.env.production?

        # IRB_USE_AUTOCOMPLETE was added in https://github.com/ruby/irb/pull/469
        IRB.conf[:USE_AUTOCOMPLETE] = ENV.fetch("IRB_USE_AUTOCOMPLETE", "false") == "true"
      end
    end
  end

  IRB.singleton_class.prepend(IrbNoHistory)
end
