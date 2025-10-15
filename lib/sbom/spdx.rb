# frozen_string_literal: true

module Sbom
  class SPDX
    class << self
      def licenses
        ::Gitlab::SPDX::Catalogue
          .latest
          .licenses
          .reject(&:deprecated)
      end

      def identifiers
        @identifiers ||= licenses.pluck(:id).to_set # rubocop:disable CodeReuse/ActiveRecord -- Array#pluck
      end

      def valid_identifier?(id)
        identifiers.include?(id)
      end
    end
  end
end
