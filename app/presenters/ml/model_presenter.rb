# frozen_string_literal: true

module Ml
  class ModelPresenter < Gitlab::View::Presenter::Delegated
    presents ::Ml::Model, as: :model

    def latest_version_name
      model.latest_version&.version
    end

    def latest_package_path
      return unless model.latest_version&.package_id.present?

      Gitlab::Routing.url_helpers.project_package_path(model.project, model.latest_version.package_id)
    end
  end
end
