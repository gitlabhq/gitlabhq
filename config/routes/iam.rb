# frozen_string_literal: true

namespace :iam do
  resource :consent, only: [:show], controller: :consent do
    member do
      post :accept
      post :reject
    end
  end
end
