# frozen_string_literal: true

resources :organizations, only: [], param: :organization_path, controller: 'organizations/organizations' do
  member do
    get :directory
  end
end
