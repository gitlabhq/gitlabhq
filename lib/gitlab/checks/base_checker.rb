# frozen_string_literal: true

module Gitlab
  module Checks
    class BaseChecker
      include Gitlab::Utils::StrongMemoize

      attr_reader :change_access
      delegate(*ChangeAccess::ATTRIBUTES, to: :change_access)

      def initialize(change_access)
        @change_access = change_access
      end

      def validate!
        raise NotImplementedError
      end

      private

      def deletion?
        Gitlab::Git.blank_ref?(newrev)
      end

      def update?
        !Gitlab::Git.blank_ref?(oldrev) && !deletion?
      end

      def updated_from_web?
        protocol == 'web'
      end

      def tag_exists?
        project.repository.tag_exists?(tag_name)
      end
    end
  end
end
