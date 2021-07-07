# frozen_string_literal: true

module API
  module Entities
    class PlanLimit < Grape::Entity
      expose :conan_max_file_size
      expose :generic_packages_max_file_size
      expose :maven_max_file_size
      expose :npm_max_file_size
      expose :nuget_max_file_size
      expose :pypi_max_file_size
      expose :terraform_module_max_file_size
    end
  end
end
