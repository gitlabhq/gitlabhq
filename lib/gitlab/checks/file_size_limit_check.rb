# frozen_string_literal: true

module Gitlab
  module Checks
    class FileSizeLimitCheck < BaseBulkChecker
      include ActionView::Helpers::NumberHelper

      def validate!
        nil
      end

      private

      # rubocop:disable Gitlab/NoCodeCoverageComment -- This is fully overriden in EE,Lint/MissingCopEnableDirective
      # :nocov:
      def file_size_limit
        nil
      end
      # :nocov:
      # rubocop:enable Gitlab/NoCodeCoverageComment
    end
  end
end

Gitlab::Checks::FileSizeLimitCheck.prepend_mod
