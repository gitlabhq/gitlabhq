# frozen_string_literal: true

module Packages
  module Nuget
    module VersionNormalizable
      extend ActiveSupport::Concern

      LEADING_ZEROES_REGEX = /^(?!0$)0+(?=\d)/

      included do
        before_validation :set_normalized_version, on: %i[create update]

        private

        def set_normalized_version
          return unless package

          self.normalized_version = normalize
        end

        def normalize
          version = remove_leading_zeroes
          version = remove_build_metadata(version)
          version = omit_zero_in_fourth_part(version)
          append_suffix(version)
        end

        def remove_leading_zeroes
          package_version.split('.').map { |part| part.sub(LEADING_ZEROES_REGEX, '') }.join('.')
        end

        def remove_build_metadata(version)
          version.split('+').first.downcase
        end

        def omit_zero_in_fourth_part(version)
          parts = version.split('.')
          parts[3] = nil if parts.fourth == '0' && parts.third.exclude?('-')
          parts.compact.join('.')
        end

        def append_suffix(version)
          version << '.0.0' if version.count('.') == 0
          version << '.0' if version.count('.') == 1
          version
        end
      end
    end
  end
end
