# frozen_string_literal: true

module API
  module Validations
    module Validators
      class ProjectPortable < Grape::Validations::Validators::Base
        def validate_param!(attr_name, params)
          portable = params[attr_name]

          portable_relations = ::BulkImports::FileTransfer.config_for(::Project.new).portable_relations
          return if portable_relations.include?(portable)

          raise Grape::Exceptions::Validation.new(
            params: [@scope.full_name(attr_name)],
            message: "is not portable"
          )
        end
      end
    end
  end
end
