# frozen_string_literal: true

module Gitlab
  module Backup
    module Cli
      module Utils
        # Run tar command to create or extract content from an archive
        class Tar
          # Returns the version of tar command available
          #
          # @return [String] the first line of `--version` output
          def version
            version = Shell::Command.new(cmd, '--version').capture.stdout.dup
            version.force_encoding('locale').split("\n").first
          end

          def cmd
            @cmd ||= if gtar_available?
                       # In BSD/Darwin we can get GNU tar by running 'gtar' instead
                       'gtar'
                     else
                       'tar'
                     end
          end

          private

          def gtar_available?
            Dependencies.executable_exist?('gtar')
          end
        end
      end
    end
  end
end
