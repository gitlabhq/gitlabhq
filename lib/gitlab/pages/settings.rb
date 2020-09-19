# frozen_string_literal: true

module Gitlab
  module Pages
    class Settings < ::SimpleDelegator
      DiskAccessDenied = Class.new(StandardError)

      def path
        if ::Gitlab::Runtime.web_server? && !::Gitlab::Runtime.test_suite?
          raise DiskAccessDenied
        end

        super
      end
    end
  end
end
