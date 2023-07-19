# frozen_string_literal: true

module Ml
  class ModelsIndexPresenter
    def initialize(models)
      @models = models
    end

    def present
      data = @models.map do |m|
        {
          name: m.name,
          version: m.version,
          path: Gitlab::Routing.url_helpers.project_package_path(m.project, m)
        }
      end

      Gitlab::Json.generate({ models: data })
    end
  end
end
