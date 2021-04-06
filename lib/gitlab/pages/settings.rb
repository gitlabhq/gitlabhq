# frozen_string_literal: true

module Gitlab
  module Pages
    class Settings < ::SimpleDelegator
      DiskAccessDenied = Class.new(StandardError)

      def path
        ::Gitlab::ErrorTracking.track_exception(DiskAccessDenied.new) if disk_access_denied?

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
    end
  end
end
