# frozen_string_literal: true

module Gitlab
  module Utils
    module FileInfo
      class << self
        # Returns true if:
        # - File or directory is a symlink.
        # - File shares a hard link.
        def linked?(file)
          stat = to_file_stat(file)

          stat.symlink? || shares_hard_link?(stat)
        end

        # Returns:
        # - true if file shares a hard link with another file.
        # - false if file is a directory, as directories cannot be hard linked.
        def shares_hard_link?(file)
          stat = to_file_stat(file)

          stat.file? && stat.nlink > 1
        end

        private

        def to_file_stat(filepath_or_stat)
          return filepath_or_stat if filepath_or_stat.is_a?(File::Stat)

          File.lstat(filepath_or_stat)
        end
      end
    end
  end
end
