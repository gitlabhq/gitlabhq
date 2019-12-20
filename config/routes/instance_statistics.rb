# frozen_string_literal: true

namespace :instance_statistics do
  root to: redirect('-/instance_statistics/dev_ops_score')

  resources :cohorts, only: :index
  resources :dev_ops_score, only: :index
end
