module Clusters
  class BaseHelmService
    attr_accessor :app

    def initialize(app)
      @app = app
    end

    protected

    def helm
      return @helm if defined?(@helm)

      @helm = @app.cluster.helm
    end
  end
end
