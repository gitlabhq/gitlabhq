# frozen_string_literal: true

module Gitlab
  module Cng
    module Helpers
      module Utils
        # Global tmp dir for file operations
        #
        # @return [String]
        def self.tmp_dir
          @tmp_dir ||= Dir.mktmpdir("cng")
        end
      end
    end
  end
end
