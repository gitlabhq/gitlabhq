# frozen_string_literal: true

module Clusters
  module Agents
    class DashboardController < ApplicationController
      include KasCookie

      before_action :check_feature_flag!
      before_action :find_agent
      before_action :authorize_read_cluster_agent!
      before_action :set_kas_cookie, only: [:show], if: -> { current_user }

      feature_category :deployment_management

      def show
        head :ok
      end

      private

      def find_agent
        @agent = ::Clusters::Agent.find(params[:agent_id])
      end

      def check_feature_flag!
        not_found unless ::Feature.enabled?(:k8s_dashboard, current_user)
      end

      def authorize_read_cluster_agent!
        not_found unless can?(current_user, :read_cluster_agent, @agent)
      end
    end
  end
end
