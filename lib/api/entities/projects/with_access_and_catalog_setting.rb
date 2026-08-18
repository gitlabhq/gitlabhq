# frozen_string_literal: true

module API
  module Entities
    module Projects
      # `Entities::ProjectWithAccess` extended with the CI/CD Catalog setting.
      class WithAccessAndCatalogSetting < ::API::Entities::ProjectWithAccess
        include CatalogSetting
      end
    end
  end
end
