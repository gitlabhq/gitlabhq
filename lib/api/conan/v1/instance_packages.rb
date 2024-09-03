# frozen_string_literal: true

# Conan Instance-Level Package Manager Client API
module API
  module Conan
    module V1
      class InstancePackages < ::API::Base
        helpers do
          def search_project
            nil
          end
        end

        namespace 'packages/conan/v1' do
          include ::API::Concerns::Packages::ConanEndpoints
        end
      end
    end
  end
end
