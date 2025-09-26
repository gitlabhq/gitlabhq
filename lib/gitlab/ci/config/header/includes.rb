# frozen_string_literal: true

module Gitlab
  module Ci
    class Config
      module Header
        class Includes < ::Gitlab::Config::Entry::ComposableArray
          include ::Gitlab::Ci::Config::Entry::Concerns::BaseIncludes

          def composable_class
            Header::Include
          end
        end
      end
    end
  end
end
