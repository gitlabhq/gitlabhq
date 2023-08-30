# frozen_string_literal: true

module API
  module Validations
    module Validators
      module BulkImports
        class DestinationSlugPath < Grape::Validations::Validators::Base
          def validate_param!(attr_name, params)
            if Feature.disabled?(:restrict_special_characters_in_namespace_path)
              return if params[attr_name] =~ Gitlab::Regex.group_path_regex

              raise Grape::Exceptions::Validation.new(
                params: [@scope.full_name(attr_name)],
                message: "#{Gitlab::Regex.group_path_regex_message} " \
                         "It can only contain alphanumeric characters, periods, underscores, and dashes. " \
                         "For example, 'destination_namespace' not 'destination/namespace'"
              )
            else
              return if params[attr_name] =~ Gitlab::Regex.oci_repository_path_regex

              raise Grape::Exceptions::Validation.new(
                params: [@scope.full_name(attr_name)],
                message: "#{Gitlab::Regex.oci_repository_path_regex_message} " \
                         "It can only contain alphanumeric characters, periods, underscores, and dashes. " \
                         "For example, 'destination_namespace' not 'destination/namespace'"
              )

            end
          end
        end

        class DestinationNamespacePath < Grape::Validations::Validators::Base
          def validate_param!(attr_name, params)
            return if params[attr_name].blank?
            return if NamespacePathValidator.valid_path?(params[attr_name])

            raise Grape::Exceptions::Validation.new(
              params: [@scope.full_name(attr_name)],
              message: Gitlab::Regex.bulk_import_destination_namespace_path_regex_message
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
                       "For example, 'source/full/path' not 'https://example.com/source/full/path'" \
            )
          end
        end
      end
    end
  end
end
