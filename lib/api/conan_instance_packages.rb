# frozen_string_literal: true

# Conan Instance-Level Package Manager Client API
module API
  class ConanInstancePackages < Grape::API::Instance
    namespace 'packages/conan/v1' do
      include ConanPackageEndpoints
    end
  end
end
