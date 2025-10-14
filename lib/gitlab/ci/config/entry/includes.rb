# frozen_string_literal: true

module Gitlab
  module Ci
    class Config
      module Entry
        ##
        # Entry that represents a list of include.
        #
        class Includes < ::Gitlab::Config::Entry::ComposableArray
          include ::Gitlab::Ci::Config::Entry::Concerns::BaseIncludes

          def composable_class
            Entry::Include
          end
        end
      end
    end
  end
end
