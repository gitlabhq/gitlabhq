# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    # rubocop:disable Style/Documentation
    class PopulateUuidsForSecurityFindings
      NOP_RELATION = Class.new { def each_batch(*); end }

      def self.security_findings
        NOP_RELATION.new
      end

      def perform(*_scan_ids); end
    end
  end
end

Gitlab::BackgroundMigration::PopulateUuidsForSecurityFindings.prepend_mod_with('Gitlab::BackgroundMigration::PopulateUuidsForSecurityFindings')
