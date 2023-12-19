# frozen_string_literal: true

# All routing related to gcp
# that is already under /-/ scope only

scope format: false do
  namespace :gcp do
    namespace :artifact_registry do
      resources :docker_images, only: :index
      resources :setup, only: :new
    end
  end
end
