# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    # This class updates vulnerabilities entities with state dismissed
    class PopulateDismissedStateForVulnerabilities
      class Vulnerability < ActiveRecord::Base # rubocop:disable Style/Documentation
        self.table_name = 'vulnerabilities'
      end

      def perform(*vulnerability_ids)
        Vulnerability.where(id: vulnerability_ids).update_all(state: 2)
        PopulateMissingVulnerabilityDismissalInformation.new.perform(*vulnerability_ids)
      end
    end
  end
end
