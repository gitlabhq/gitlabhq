# frozen_string_literal: true

module API
  module Validations
    module Validators
      module BulkImports
        class DestinationSlugPath < Grape::Validations::Validators::Base
          def validate_param!(attr_name, params)
            return if Gitlab::Regex.oci_repository_path_regex.match?(params[attr_name])

            raise Grape::Exceptions::Validation.new(
              params: [@scope.full_name(attr_name)],
              message: "#{Gitlab::Regex.oci_repository_path_regex_message} " \
                       "For example, 'destination_namespace' not 'destination/namespace'"
            )
          end
        end

        class DestinationNamespacePath < Grape::Validations::Validators::Base
          def validate_param!(attr_name, params)
            return if params[attr_name].blank?
            return if NamespacePathValidator.valid_path?(params[attr_name])

            raise Grape::Exceptions::Validation.new(
              params: [@scope.full_name(attr_name)],
              message: "must be a relative path and not include protocol, sub-domain, or domain information. " \
                       "For example, 'destination/full/path' not 'https://example.com/destination/full/path'"
            )
          end
        end

        class SourceFullPath < Grape::Validations::Validators::Base
          def validate_param!(attr_name, params)
            full_path = params[attr_name]

            return if params['source_type'] == 'group_entity' && NamespacePathValidator.valid_path?(full_path)
            return if params['source_type'] == 'project_entity' && ProjectPathValidator.valid_path?(full_path)

            raise Grape::Exceptions::Validation.new(
              params: [@scope.full_name(attr_name)],
              message: "must be a relative path and not include protocol, sub-domain, or domain information. " \
                       "For example, 'source/full/path' not 'https://example.com/source/full/path'"
            )
          end
        end
      end
    end
  end
end
