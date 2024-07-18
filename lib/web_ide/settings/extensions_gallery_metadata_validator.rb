# frozen_string_literal: true

module WebIde
  module Settings
    class ExtensionsGalleryMetadataValidator
      include Messages

      # @param [Hash] context
      # @return [Gitlab::Fp::Result]
      def self.validate(context)
        unless context.fetch(:requested_setting_names).include?(:vscode_extensions_gallery_metadata)
          return Gitlab::Fp::Result.ok(context)
        end

        context => { settings: Hash => settings }
        settings => { vscode_extensions_gallery_metadata: Hash => extensions_gallery_metadata }

        validatable_hash = make_hash_validatable_by_json_schemer(extensions_gallery_metadata)
        errors = validate_against_schema(validatable_hash)

        if errors.none?
          Gitlab::Fp::Result.ok(context)
        else
          Gitlab::Fp::Result.err(
            SettingsVscodeExtensionsGalleryMetadataValidationFailed.new(details: errors.join(". "))
          )
        end
      end

      # @param [Hash] hash
      # @return [Hash]
      def self.make_hash_validatable_by_json_schemer(hash)
        hash
          .deep_stringify_keys
          .transform_values { |v| v.is_a?(Symbol) ? v.to_s : v }
      end

      # @param [Hash] hash_to_validate
      # @return [Array]
      def self.validate_against_schema(hash_to_validate)
        schema = {
          "properties" => {
            "enabled" => {
              "type" => "boolean"
            }
          },
          # do conditional check that "enabled" is boolean type
          "if" => {
            "properties" => {
              "enabled" => {
                "type" => "boolean"
              }
            }
          },
          "then" => {
            # "enabled" is boolean, do conditional check for "enabled" value
            "if" => {
              "properties" => {
                "enabled" => {
                  "const" => true
                }
              }
            },
            "then" => {
              # "enabled" is true, "disabled_reason" is not required
              "required" => %w[enabled]
            },
            "else" => {
              # "enabled" is false, "disabled_reason" is required
              "required" => %w[enabled disabled_reason],
              "properties" => {
                "disabled_reason" => {
                  "type" => "string"
                }
              }
            }
          }
        }

        schemer = JSONSchemer.schema(schema)
        errors = schemer.validate(hash_to_validate)
        errors.map { |error| JSONSchemer::Errors.pretty(error) }
      end
      private_class_method :make_hash_validatable_by_json_schemer, :validate_against_schema
    end
  end
end
