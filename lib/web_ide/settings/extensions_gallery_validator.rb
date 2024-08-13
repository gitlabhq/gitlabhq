# frozen_string_literal: true

module WebIde
  module Settings
    class ExtensionsGalleryValidator
      include Messages

      # @param [Hash] context
      # @return [Gitlab::Fp::Result]
      def self.validate(context)
        unless context.fetch(:requested_setting_names).intersect?([:vscode_extensions_gallery])
          return Gitlab::Fp::Result.ok(context)
        end

        context => { settings: Hash => settings }
        settings => { vscode_extensions_gallery: Hash => vscode_extensions_gallery }

        # NOTE: We deep_stringify_keys here, so we can still pass keys as symbols during tests.
        #       This is the only place where keys need to be strings, because of the JSON schema
        #       validation, all other places we convert and work with the keys as symbols.
        errors = validate_against_schema(vscode_extensions_gallery.deep_stringify_keys)

        if errors.none?
          Gitlab::Fp::Result.ok(context)
        else
          Gitlab::Fp::Result.err(SettingsVscodeExtensionsGalleryValidationFailed.new(details: errors.join(". ")))
        end
      end

      # @param [Hash] hash_to_validate
      # @return [Array]
      def self.validate_against_schema(hash_to_validate)
        schema = {
          "required" =>
            %w[
              service_url
              item_url
              resource_url_template
            ],
          "properties" => {
            "service_url" => {
              "type" => "string"
            },
            "item_url" => {
              "type" => "string"
            },
            "resource_url_template" => {
              "type" => "string"
            },
            "control_url" => {
              "type" => "string"
            },
            "nls_base_url" => {
              "type" => "string"
            },
            "publisher_url" => {
              "type" => "string"
            }
          }
        }

        schemer = JSONSchemer.schema(schema)
        errors = schemer.validate(hash_to_validate)
        errors.map { |error| JSONSchemer::Errors.pretty(error) }
      end

      private_class_method :validate_against_schema
    end
  end
end
