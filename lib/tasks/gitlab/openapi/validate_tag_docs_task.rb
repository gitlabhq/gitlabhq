# frozen_string_literal: true

module Tasks
  module Gitlab
    module Openapi
      class ValidateTagDocsTask
        def self.run = new.run

        def run
          result = validator.validate(code_tag_slugs)

          unless result.valid?
            print_errors(format_all_errors(result))

            abort
          end

          puts "API tag content is valid (#{result.checked} #{'file'.pluralize(result.checked)})"
        end

        private

        def validator
          @validator ||= validator_class.new
        end

        def validator_class
          require_relative '../../../../tooling/docs/api/tag_content_validator'

          ::Docs::Api::TagContentValidator
        end

        def code_tag_slugs
          @code_tag_slugs ||= api_classes.flat_map do |api_class|
            api_class.routes.flat_map { |route| route.settings.dig(:description, :tags) }
          end.compact.uniq
        end

        def api_classes
          excluded = ::Gitlab::GrapeOpenapi.configuration.excluded_api_classes

          # Rails 8 draws routes lazily, so we need to reference the root API first so that it mounts and
          # registers every API class in API::Base.descendants.
          ::API::API # rubocop:disable Lint/Void -- Referenced for its load side effect
          ::API::Base.descendants.reject { |api_class| excluded.include?(api_class.name) }
        end

        def relative_path(path)
          Pathname.new(path).relative_path_from(Rails.root).to_s
        end

        def print_errors(formatted_errors)
          puts "#######################################################################\n#"
          puts formatted_errors.gsub(/^/, '#  ').gsub(/\s+$/, '')
          puts "#######################################################################"
        end

        def format_all_errors(result)
          format_schema_errors(result.schema) +
            format_error_list(:orphan, result.orphan) +
            format_error_list(:description, result.description)
        end

        def format_schema_errors(violations)
          return '' if violations.empty?

          out = "#{error_messages[:schema]}\n\n"

          violations.each do |path, errors|
            out += "  - #{relative_path(path)}\n"
            errors.each { |error| out += "      - #{JSONSchemer::Errors.pretty(error)}\n" }
          end

          "#{out}\n"
        end

        def format_error_list(kind, paths)
          return '' if paths.empty?

          out = "#{error_messages[kind]}\n\n"
          paths.each { |path| out += "  - #{relative_path(path)}\n" }

          "#{out}\n"
        end

        def error_messages
          {
            schema: "The following API tag content files have invalid front matter." \
              "\nAllowed keys are defined in #{relative_path(validator.json_schema_file)}." \
              "\nFront matter that is not valid YAML is treated as empty.",
            orphan: "The following API tag content files do not match a tag declared by any API endpoint." \
              "\nRename the file to match the tag slug used in `desc ... tags`, or delete it.",
            description: "The following API tag content files have an empty description." \
              "\nAdd the description as the markdown body, below the front matter."
          }
        end
      end
    end
  end
end
