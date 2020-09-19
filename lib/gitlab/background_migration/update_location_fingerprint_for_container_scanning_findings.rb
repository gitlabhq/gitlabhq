# frozen_string_literal: true
# rubocop:disable Style/Documentation

module Gitlab
  module BackgroundMigration
    class UpdateLocationFingerprintForContainerScanningFindings
      def perform(start_id, stop_id)
      end
    end
  end
end

Gitlab::BackgroundMigration::UpdateLocationFingerprintForContainerScanningFindings.prepend_if_ee('EE::Gitlab::BackgroundMigration::UpdateLocationFingerprintForContainerScanningFindings')
