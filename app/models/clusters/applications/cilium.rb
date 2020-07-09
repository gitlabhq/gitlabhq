# frozen_string_literal: true

module Clusters
  module Applications
    class Cilium < ApplicationRecord
      self.table_name = 'clusters_applications_cilium'

      include ::Clusters::Concerns::ApplicationCore
      include ::Clusters::Concerns::ApplicationStatus

      def allowed_to_uninstall?
        false
      end
    end
  end
end
