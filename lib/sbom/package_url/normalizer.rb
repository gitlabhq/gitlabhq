# frozen_string_literal: true

module Sbom
  class PackageUrl
    class Normalizer
      # Based on https://peps.python.org/pep-0503/#normalized-names
      PYPI_REGEX = /[-_\.]+/

      def initialize(type:, text:)
        @type = type
        @text = text
      end

      def normalize_namespace
        return if text.nil?

        normalize
      end

      def normalize_name
        raise ArgumentError, 'Name is required' if text.nil?

        normalize
      end

      private

      def normalize
        case type
        when 'bitbucket', 'github', 'golang'
          downcase
        when 'pypi'
          normalize_pypi
        else
          text
        end
      end

      attr_reader :type, :text

      def downcase
        text.downcase
      end

      def normalize_pypi
        downcase.gsub(PYPI_REGEX, '-')
      end
    end
  end
end
