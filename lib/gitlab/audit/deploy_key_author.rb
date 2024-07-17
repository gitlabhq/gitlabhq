# frozen_string_literal: true

module Gitlab
  module Audit
    class DeployKeyAuthor < Gitlab::Audit::NullAuthor
      def initialize(name: nil)
        super(id: -3, name: name)
      end

      def name
        @name || _('Deploy key')
      end
    end
  end
end
