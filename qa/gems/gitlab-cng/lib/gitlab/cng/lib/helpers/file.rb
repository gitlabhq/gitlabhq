# frozen_string_literal: true

require "fileutils"

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

        # gitlab-cng configuration directory
        #
        # @return [String]
        def self.config_dir
          @config_dir ||= File.join(Dir.home, ".gitlab-cng").tap { |dir| FileUtils.mkdir_p(dir) }
        end
      end
    end
  end
end
