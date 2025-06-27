# frozen_string_literal: true

class DeploymentCluster < ApplicationRecord
  include IgnorableColumns

  ignore_column :deployment_id_convert_to_bigint, :cluster_id_convert_to_bigint,
    remove_with: '18.3', remove_after: '2025-09-01'

  belongs_to :deployment, optional: false
  belongs_to :cluster, optional: false, class_name: 'Clusters::Cluster'
end
