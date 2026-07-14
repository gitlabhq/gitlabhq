# frozen_string_literal: true

module Gitlab
  module Audit
    class DeployKeyAuthor < Gitlab::Audit::NullAuthor
      def initialize(name: nil)
        super(id: DEPLOY_KEY_AUTHOR_ID, name: name)
      end

      def name
        @name || _('Deploy key')
      end
    end
  end
end
