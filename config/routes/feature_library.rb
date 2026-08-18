# frozen_string_literal: true

namespace :onboarding do
  scope '/feature_library', controller: :feature_library, as: :feature_library do
    get '/search' => :search, as: :search
    get '/ai_search' => :ai_search, as: :ai_search
  end
end
