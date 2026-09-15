# frozen_string_literal: true

module Gitlab
  module Utils
    # Class-level execute for one-shot services where callers don't need the instance.
    # The ... forwarding prevents the class signature from drifting from initialize.
    module Executable
      extend ActiveSupport::Concern

      class_methods do
        def execute(...)
          new(...).execute
        end
      end
    end
  end
end
