# frozen_string_literal: true

module Gitlab
  module Backup
    module Cli
      module Targets
        # Abstract class used to implement a Backup Target
        class Target
          attr_reader :context

          def initialize(context = nil)
            @context = context
          end

          def asynchronous?
            false
          end

          # dump task backup to `path`
          #
          # @param [String] path fully qualified backup task destination
          def dump(path)
            raise NotImplementedError
          end

          # restore task backup from `path`
          def restore(path)
            raise NotImplementedError
          end
        end
      end
    end
  end
end
