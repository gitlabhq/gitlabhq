# frozen_string_literal: true

module Gitlab
  module Backup
    module Cli
      module Targets
        # Abstract class used to implement a Backup Target
        class Target
          # Backup creation and restore option flags
          #
          # TODO: Migrate to a unified backup specific Options implementation
          # @return [::Backup::Options]
          attr_reader :options

          def initialize(options:)
            @options = options
          end

          def asynchronous?
            false
          end

          # dump task backup to `destination`
          #
          # @param [String] destination fully qualified backup task destination
          # or a backup id - a unique identifier for a cloud backup
          def dump(destination)
            raise NotImplementedError
          end

          # restore task backup from `source`
          def restore(source)
            raise NotImplementedError
          end
        end
      end
    end
  end
end
