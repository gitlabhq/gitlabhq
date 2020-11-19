# frozen_string_literal: true
module API
  class NpmInstancePackages < ::API::Base
    helpers ::API::Helpers::Packages::Npm

    feature_category :package_registry

    rescue_from ActiveRecord::RecordInvalid do |e|
      render_api_error!(e.message, 400)
    end

    namespace 'packages/npm' do
      include ::API::Concerns::Packages::NpmEndpoints
    end
  end
end
