# frozen_string_literal: true

module Gitlab
  module Pages
    class Settings < ::SimpleDelegator
      DiskAccessDenied = Class.new(StandardError)

      def path
        if ::Gitlab::Runtime.web_server? && ENV['GITLAB_PAGES_DENY_DISK_ACCESS'] == '1'
          begin
            raise DiskAccessDenied
          rescue DiskAccessDenied => ex
            ::Gitlab::ErrorTracking.track_exception(ex)
          end
        end

        super
      end
    end
  end
end
