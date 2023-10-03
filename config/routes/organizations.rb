# frozen_string_literal: true

resources(
  :organizations,
  only: [:show, :index, :new],
  param: :organization_path,
  module: :organizations
) do
  member do
    get :groups_and_projects

    resource :settings, only: [], as: :settings_organization do
      get :general
    end
  end
end
