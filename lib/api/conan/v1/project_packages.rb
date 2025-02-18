# frozen_string_literal: true

# Conan Project-Level Package Manager Client API
module API
  module Conan
    module V1
      class ProjectPackages < ::API::Base
        params do
          requires :id, types: [String, Integer], desc: 'The ID or URL-encoded path of the project'
        end

        resource :projects, requirements: API::NAMESPACE_OR_PROJECT_REQUIREMENTS do
          namespace ':id/packages/conan/v1' do
            include ::API::Concerns::Packages::Conan::V1Endpoints
          end
        end
      end
    end
  end
end
