# frozen_string_literal: true

namespace :members do
  namespace :mailgun do
    resources :permanent_failures, only: [:create]
  end
end
