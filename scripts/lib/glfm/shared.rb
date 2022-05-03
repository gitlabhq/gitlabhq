# frozen_string_literal: true
require 'fileutils'

module Glfm
  module Shared
    def write_file(file_path, file_content_string)
      FileUtils.mkdir_p(File.dirname(file_path))
      # NOTE: We don't use the block form of File.open because we want to be able to easily
      # mock it for testing.
      io = File.open(file_path, 'w')
      io.binmode
      io.write(file_content_string)
      # NOTE: We are using #fsync + #close_write instead of just #close`, in order to unit test
      # with a real StringIO and not just a mock object.
      io.fsync
      io.close_write
    end

    # All script output goes through this method. This makes it easy to mock in order to prevent
    # output from being printed to the console during tests. We don't want to directly mock
    # Kernel#puts, because that could interfere or cause spurious test failures when #puts is used
    # for debugging. And for some reason RuboCop says `rubocop:disable Rails/Output` would be
    # redundant here, so not including it.
    def output(string)
      puts string
    end
  end
end
