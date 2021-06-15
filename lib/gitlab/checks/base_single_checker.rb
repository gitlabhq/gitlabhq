# frozen_string_literal: true

module Gitlab
  module Checks
    class BaseSingleChecker < BaseChecker
      attr_reader :change_access
      delegate(*SingleChangeAccess::ATTRIBUTES, to: :change_access)

      def initialize(change_access)
        @change_access = change_access
      end

      private

      def creation?
        Gitlab::Git.blank_ref?(oldrev)
      end

      def deletion?
        Gitlab::Git.blank_ref?(newrev)
      end

      def update?
        !creation? && !deletion?
      end

      def tag_exists?
        project.repository.tag_exists?(tag_name)
      end
    end
  end
end

Gitlab::Checks::BaseSingleChecker.prepend_mod_with('Gitlab::Checks::BaseSingleChecker')
