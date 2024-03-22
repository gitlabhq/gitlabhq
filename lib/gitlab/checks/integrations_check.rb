# frozen_string_literal: true

module Gitlab
  module Checks
    class IntegrationsCheck < ::Gitlab::Checks::BaseBulkChecker
      def validate!
        ::Gitlab::Checks::Integrations::BeyondIdentityCheck.new(self).validate!
      end
    end
  end
end

Gitlab::Checks::IntegrationsCheck.prepend_mod
