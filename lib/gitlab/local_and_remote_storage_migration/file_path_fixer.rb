# frozen_string_literal: true

module Gitlab
  module LocalAndRemoteStorageMigration
    module FilePathFixer
      extend self

      # Fixes the file path if necessary and returns the new path (or nil if nothing changed)
      def fix_file_path!(artifact)
        return if artifact.file_final_path.blank?

        desired_file_name = artifact.file_identifier
        final_file_dir = File.dirname(artifact.file.path)
        remote_file_name = File.basename(artifact.file_final_path)

        return if desired_file_name == remote_file_name

        return if File.exist?(File.join(final_file_dir, desired_file_name))

        to_be_renamed_file = File.join(final_file_dir, remote_file_name)
        return unless File.exist?(to_be_renamed_file)

        final_file_name = File.join(final_file_dir, desired_file_name)
        File.rename(to_be_renamed_file, final_file_name)
        final_file_name
      end
    end
  end
end
