# frozen_string_literal: true

# Conan Instance-Level Package Manager Client API
module API
  module Conan
    module V1
      class InstancePackages < ::API::Base
        namespace 'packages/conan/v1' do
          include ::API::Concerns::Packages::Conan::V1Endpoints

          helpers do
            def search_project
              nil
            end
          end
        end
      end
    end
  end
end
