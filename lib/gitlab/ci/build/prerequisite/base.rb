# frozen_string_literal: true

module Gitlab
  module Ci
    module Build
      module Prerequisite
        class Base
          include Utils::StrongMemoize

          attr_reader :build

          def initialize(build)
            @build = build
          end

          def unmet?
            raise NotImplementedError
          end

          def complete!
            raise NotImplementedError
          end
        end
      end
    end
  end
end
