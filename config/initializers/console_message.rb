# frozen_string_literal: true

if Gitlab::Runtime.console?
  # Stop irb from writing a history file by default.
  module IrbNoHistory
    def init_config(*)
      super

      IRB.conf[:SAVE_HISTORY] = false
    end
  end

  IRB.singleton_class.prepend(IrbNoHistory)
end
