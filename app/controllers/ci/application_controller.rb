module Ci
  class ApplicationController < ::ApplicationController
    def self.railtie_helpers_paths
      "app/helpers/ci"
    end
  end
end
