module Clusters
  class InstallTillerService < BaseService
    def execute
      ensure_namespace
      install
    end

    private

    def kubernetes_service
      return @kubernetes_service if defined?(@kubernetes_service)

      @kubernetes_service = project&.kubernetes_service
    end

    def ensure_namespace
      kubernetes_service&.ensure_namespace!
    end

    def install
      kubernetes_service&.helm_client&.init!
    end
  end
end
