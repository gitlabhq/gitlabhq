# frozen_string_literal: true

module Gitlab
  module Pages
    class Settings < ::SimpleDelegator
      DiskAccessDenied = Class.new(StandardError)

      def path
        report_denied_disk_access

        super
      end

      def local_store
        @local_store ||= ::Gitlab::Pages::Stores::LocalStore.new(super)
      end

      private

      def disk_access_denied?
        return true unless ::Settings.pages.local_store&.enabled

        ::Gitlab::Runtime.web_server? && !::Gitlab::Runtime.test_suite?
      end

      def report_denied_disk_access
        raise DiskAccessDenied if disk_access_denied?
      rescue => e
        ::Gitlab::ErrorTracking.track_exception(e)
      end
    end
  end
end
