# frozen_string_literal: true

module Groups
  class ClustersController < Groups::ApplicationController
    include ::CreatesCluster

    # CreatesCluster concern
    alias_method :cluster_parent, :group

    before_action :authorize_create_cluster!, only: [:new, :create_gcp, :create_user]

    private

    def authorize_create_cluster!
      unless can?(current_user, :create_cluster, group)
        access_denied!
      end
    end
  end
end
