# frozen_string_literal: true

module Clusters
  class ClusterEnabledGrant < ApplicationRecord
    self.table_name = 'cluster_enabled_grants'

    belongs_to :namespace
  end
end
