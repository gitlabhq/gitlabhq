# frozen_string_literal: true

module Gitlab
  module Audit
    class DeployTokenAuthor < Gitlab::Audit::NullAuthor
      def initialize(name: nil)
        super(id: -2, name: name)
      end

      # Events that are authored by a deploy token, should be
      # shown as authored by `Deploy Token` in the UI.
      def name
        @name || _('Deploy Token')
      end
    end
  end
end
