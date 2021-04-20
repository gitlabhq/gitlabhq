# frozen_string_literal: true

module Clusters
  class DestroyService
    attr_reader :current_user, :params

    def initialize(user = nil, params = {})
      @current_user = user
      @params = params.dup
      @response = {}
    end

    def execute(cluster)
      cleanup? ? start_cleanup!(cluster) : destroy_cluster!(cluster)

      @response
    end

    private

    def cleanup?
      Gitlab::Utils.to_boolean(params[:cleanup])
    end

    def start_cleanup!(cluster)
      cluster.start_cleanup!
      @response[:message] = _('Kubernetes cluster integration and resources are being removed.')
    end

    def destroy_cluster!(cluster)
      cluster.destroy!
      @response[:message] = _('Kubernetes cluster integration was successfully removed.')
    end
  end
end
