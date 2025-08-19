# frozen_string_literal: true

module API
  module Validations
    module Validators
      class FilePath < Grape::Validations::Validators::Base
        def validate_param!(attr_name, params)
          options = @option.is_a?(Hash) ? @option : {}
          path_allowlist = options.fetch(:allowlist, [])
          allow_initial_path_separator = options.fetch(:allow_initial_path_separator, false)
          path = params[attr_name]

          if allow_initial_path_separator
            decoded_path = ::Gitlab::Utils.decode_path(path)
            path_was_encoded = decoded_path != path

            if path_was_encoded && decoded_path.start_with?('/')
              # NOTE: This validation assumes downstream code will NOT decode the path again
              # after validation. If any component calls CGI.unescape() or similar decoding methods
              # on the validated path, it could bypass security checks. The path should be used
              # as-is after validation to maintain security guarantees.
              segments = decoded_path.split('/')
              if segments.length > 1 && segments[0].empty?
                first_dir = "/#{segments[1]}"
                path_allowlist << first_dir unless first_dir == '/'
              end
            end
          end

          Gitlab::PathTraversal.check_allowed_absolute_path_and_path_traversal!(path, path_allowlist)
        rescue StandardError
          raise Grape::Exceptions::Validation.new(
            params: [@scope.full_name(attr_name)],
            message: "should be a valid file path"
          )
        end
      end
    end
  end
end
