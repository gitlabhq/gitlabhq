# frozen_string_literal: true

module Clusters
  module Applications
    class Cilium < ApplicationRecord
      self.table_name = 'clusters_applications_cilium'

      include ::Clusters::Concerns::ApplicationCore
      include ::Clusters::Concerns::ApplicationStatus

      # Cilium can only be installed and uninstalled through the
      # cluster-applications project by triggering CI pipeline for a
      # management project. UI operations are not available for such
      # applications. More information:
      # https://docs.gitlab.com/ee/user/clusters/management_project.html
      def allowed_to_uninstall?
        false
      end
    end
  end
end
