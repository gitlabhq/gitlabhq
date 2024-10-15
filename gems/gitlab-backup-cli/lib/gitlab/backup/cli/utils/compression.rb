# frozen_string_literal: true

module Gitlab
  module Backup
    module Cli
      module Utils
        class Compression
          def self.compression_command
            Shell::Command.new('gzip -c -1')
          end

          def self.decompression_command
            Shell::Command.new('gzip -cd')
          end
        end
      end
    end
  end
end
