# frozen_string_literal: true

module Gitlab
  module Pages
    class RandomDomain
      PROJECT_PATH_LIMIT = 56

      def self.generate(project_path:)
        new(project_path: project_path).generate
      end

      def initialize(project_path:)
        @project_path = project_path
      end

      # Subdomains have a limit of 63 bytes (https://www.freesoft.org/CIE/RFC/1035/9.htm)
      # For this reason we're limiting each part of the unique subdomain
      #
      # The domain is made up of 2 parts, like: projectpath-randomstring
      # - project path: between 1 and 56 chars
      # - random hexadecimal: to ensure a random value of length 6
      def generate
        domain = project_path.byteslice(0, PROJECT_PATH_LIMIT)

        # PS.: SecureRandom.hex return an string twice the size passed as argument.
        domain.concat('-', SecureRandom.hex(3))

        # Slugify ensures the format and size (63 chars) of the given string
        Gitlab::Utils.slugify(domain)
      end

      private

      attr_reader :project_path
    end
  end
end
