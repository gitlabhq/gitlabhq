# frozen_string_literal: true

# Conan Instance-Level Package Manager Client API
module API
  class ConanInstancePackages < ::API::Base
    namespace 'packages/conan/v1' do
      include ConanPackageEndpoints
    end
  end
end
