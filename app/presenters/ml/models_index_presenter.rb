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
          version: m.latest_version&.version,
          path: package_path(m)
        }
      end

      Gitlab::Json.generate({ models: data })
    end

    private

    def package_path(model)
      return unless model.latest_version&.package.present?

      Gitlab::Routing.url_helpers.project_package_path(model.project, model.latest_version.package_id)
    end
  end
end
