# frozen_string_literal: true

# This Rake task is not ready to be used in production yet. It has been added to split up
# work across multiple MRs and will be integrated into the CI pipeline in
# future MRs.

namespace :gitlab do
  namespace :js do
    desc "Make a js file with all rails route URL helpers"
    task routes: :environment do
      require 'gitlab/js_routes'

      Gitlab::JsRoutes.generate!
    end
  end
end
