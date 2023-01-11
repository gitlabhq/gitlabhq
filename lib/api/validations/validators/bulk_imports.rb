# frozen_string_literal: true

module API
  module Validations
    module Validators
      module BulkImports
        class DestinationSlugPath < Grape::Validations::Base
          def validate_param!(attr_name, params)
            unless params[attr_name] =~ Gitlab::Regex.group_path_regex # rubocop: disable Style/GuardClause
              raise Grape::Exceptions::Validation.new(
                params: [@scope.full_name(attr_name)],
                message: "cannot start with a dash or forward slash, or end with a period or forward slash. " \
                         "It can only contain alphanumeric characters, periods, underscores, and dashes. " \
                         "E.g. 'destination_namespace' not 'destination/namespace'"
              )
            end
          end
        end

        class DestinationNamespacePath < Grape::Validations::Base
          def validate_param!(attr_name, params)
            unless params[attr_name] =~ Gitlab::Regex.bulk_import_namespace_path_regex # rubocop: disable Style/GuardClause
              raise Grape::Exceptions::Validation.new(
                params: [@scope.full_name(attr_name)],
                message: "cannot start with a dash or forward slash, or end with a period or forward slash. " \
                         "It can only contain alphanumeric characters, periods, underscores, forward slashes " \
                         "and dashes. E.g. 'destination_namespace' or 'destination/namespace'"
              )
            end
          end
        end

        class SourceFullPath < Grape::Validations::Base
          def validate_param!(attr_name, params)
            unless params[attr_name] =~ Gitlab::Regex.bulk_import_namespace_path_regex # rubocop: disable Style/GuardClause
              raise Grape::Exceptions::Validation.new(
                params: [@scope.full_name(attr_name)],
                message: "must be a relative path and not include protocol, sub-domain, or domain information. " \
                         "E.g. 'source/full/path' not 'https://example.com/source/full/path'" \
              )
            end
          end
        end
      end
    end
  end
end
