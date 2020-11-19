# frozen_string_literal: true

module Packages
  module Debian
    # Returns .deb file metadata
    class ExtractDebMetadataService
      CommandFailedError = Class.new(StandardError)

      def initialize(file_path)
        @file_path = file_path
      end

      def execute
        unless success?
          raise CommandFailedError, "The `#{cmd}` command failed (status: #{result.status}) with the following error:\n#{result.stderr}"
        end

        sections = ParseDebian822Service.new(result.stdout).execute

        sections.each_value.first
      end

      private

      def cmd
        @cmd ||= begin
          dpkg_deb_path = Gitlab.config.packages.dpkg_deb_path
          [dpkg_deb_path, '--field', @file_path]
        end
      end

      def result
        @result ||= Gitlab::Popen.popen_with_detail(cmd)
      end

      def success?
        result.status&.exitstatus == 0
      end
    end
  end
end
