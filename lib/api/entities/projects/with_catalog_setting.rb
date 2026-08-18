# frozen_string_literal: true

module API
  module Entities
    module Projects
      # `Entities::Project` extended with the CI/CD Catalog setting.
      class WithCatalogSetting < ::API::Entities::Project
        include CatalogSetting
      end
    end
  end
end
