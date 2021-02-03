# frozen_string_literal: true

if Gitlab::Sherlock.enabled?
  namespace :sherlock do
    resources :transactions, only: [:index, :show] do
      resources :queries, only: [:show]
      resources :file_samples, only: [:show]

      collection do
        delete :destroy_all
      end
    end
  end
end
