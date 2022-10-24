# frozen_string_literal: true

module Routing
  module PackagesHelper
    def package_path(package, **options)
      Gitlab::UrlBuilder.build(package, only_path: true, **options)
    end
  end
end
