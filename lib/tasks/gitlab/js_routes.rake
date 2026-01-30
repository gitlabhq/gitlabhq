# frozen_string_literal: true

namespace :gitlab do
  namespace :js do
    desc "Make a js file with all rails route URL helpers"
    task routes: :environment do
      require 'gitlab/js_routes'

      Gitlab::JsRoutes.generate!
    end
  end
end
