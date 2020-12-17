# frozen_string_literal: true

# Conan Project-Level Package Manager Client API
module API
  class ConanProjectPackages < ::API::Base
    params do
      requires :id, type: Integer, desc: 'The ID of a project', regexp: %r{\A[1-9]\d*\z}
    end

    resource :projects, requirements: API::NAMESPACE_OR_PROJECT_REQUIREMENTS do
      namespace ':id/packages/conan/v1' do
        include ::API::Concerns::Packages::ConanEndpoints
      end
    end
  end
end
