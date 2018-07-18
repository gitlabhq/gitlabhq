# frozen_string_literal: true

namespace :instance_statistics do
  root to: redirect("instance_statistics/conversational_development_index")

  resources :cohorts, only: :index
  resources :conversational_development_index, only: :index
end
