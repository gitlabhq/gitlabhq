# frozen_string_literal: true

# An environment name is not necessarily suitable for use in URLs, DNS
# or other third-party contexts, so provide a slugified version. A slug has
# the following properties:
#   * contains only lowercase letters (a-z), numbers (0-9), and '-'
#   * begins with a letter
#   * has a maximum length of 24 bytes (OpenShift limitation)
#   * cannot end with `-`
module Gitlab
  module Slug
    class Environment
      attr_reader :name

      def initialize(name)
        @name = name
      end

      def generate
        # Lowercase letters and numbers only
        slugified = name.to_s.downcase.gsub(/[^a-z0-9]/, '-')

        # Must start with a letter
        slugified = "env-#{slugified}" unless slugified.match?(/^[a-z]/)

        # Repeated dashes are invalid (OpenShift limitation)
        slugified.squeeze!('-')

        if slugified.size > 24 || slugified != name
          # Maximum length: 24 characters (OpenShift limitation)
          shorten_and_add_suffix(slugified)
        else
          # Cannot end with a dash (Kubernetes label limitation)
          slugified.chomp('-')
        end
      end

      private

      def shorten_and_add_suffix(slug)
        slug = slug[0..16]
        slug << '-' unless slug.ends_with?('-')
        slug << suffix
      end

      # Slugifying a name may remove the uniqueness guarantee afforded by it being
      # based on name (which must be unique). To compensate, we add a predictable
      # 6-byte suffix in those circumstances. This is not *guaranteed* uniqueness,
      # but the chance of collisions is vanishingly small
      def suffix
        Digest::SHA2.hexdigest(name.to_s).to_i(16).to_s(36).last(6)
      end
    end
  end
end
