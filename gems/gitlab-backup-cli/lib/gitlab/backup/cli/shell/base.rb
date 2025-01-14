# frozen_string_literal: true

module Gitlab
  module Backup
    module Cli
      module Shell
        class Base
          private

          def typecast_input!(input)
            case input
            in Pathname
              input.to_s
            else
              input
            end
          end

          # When providing an output to Open3.pipeline / spawn, we can't pass a Pathname.
          # It needs to be converted to a string, otherwise we get an error
          def typecast_output!(output)
            case output
            # Matches an array with a path followed by 'read,write' flag and permissions bit
            # E.g. [Pathname.new('/tmp/file'), 'w', 0o600] OR
            # Matches an array with a path followed by bit based flag and permissions bit
            # E.g. [Pathname.new('/tmp/file'), File::WRONLY|File::CREAT, 0o600]
            in [Pathname, String, Integer] | [Pathname, Integer, Integer]
              output[0] = output[0].to_s
              output
            in Pathname
              output.to_s
            else
              output
            end
          end
        end
      end
    end
  end
end
