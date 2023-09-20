# frozen_string_literal: true

module Sbom
  class PackageUrl
    class ArgumentValidator
      QUALIFIER_KEY_REGEXP = /^[A-Za-z\d._-]+$/
      START_WITH_NUMBER_REGEXP = /^\d/

      def initialize(package)
        @type = package.type
        @namespace = package.namespace
        @name = package.name
        @version = package.version
        @qualifiers = package.qualifiers
        @errors = []
      end

      def validate!
        validate_type
        validate_name
        validate_qualifiers
        validate_by_type

        raise ArgumentError, formatted_errors if invalid?
      end

      private

      def invalid?
        errors.present?
      end

      attr_reader :type, :namespace, :name, :version, :qualifiers, :errors

      def formatted_errors
        errors.join(', ')
      end

      def validate_type
        errors.push('Type is required') if type.blank?
      end

      def validate_name
        errors.push('Name is required') if name.blank?
      end

      def validate_qualifiers
        return if qualifiers.nil?

        keys = qualifiers.keys
        errors.push('Qualifier keys must be unique') unless keys.uniq.size == keys.size

        keys.each do |key|
          errors.push(key_error(key, 'contains illegal characters')) unless key.match?(QUALIFIER_KEY_REGEXP)
          errors.push(key_error(key, 'may not start with a number')) if key.match?(START_WITH_NUMBER_REGEXP)
        end
      end

      def key_error(key, text)
        "Qualifier key `#{key}` #{text}"
      end

      def validate_by_type
        case type
        when 'conan'
          validate_conan
        when 'cran'
          validate_cran
        when 'swift'
          validate_swift
        end
      end

      def validate_conan
        return unless namespace.blank? ^ (qualifiers.nil? || qualifiers.exclude?('channel'))

        errors.push('Conan packages require the channel be present if published in a namespace and vice-versa')
      end

      def validate_cran
        errors.push('Cran packages require a version') if version.blank?
      end

      def validate_swift
        errors.push('Swift packages require a namespace') if namespace.blank?
        errors.push('Swift packages require a version') if version.blank?
      end
    end
  end
end
