# frozen_string_literal: true

module Gitlab
  module Pages
    class RandomDomain
      PROJECT_PATH_LIMIT = 48
      SUBDOMAIN_LABEL_LIMIT = 63

      def self.generate(project_path:, namespace_path:)
        new(project_path: project_path, namespace_path: namespace_path).generate
      end

      def initialize(project_path:, namespace_path:)
        @project_path = project_path
        @namespace_path = namespace_path
      end

      # Subdomains have a limit of 63 bytes (https://www.freesoft.org/CIE/RFC/1035/9.htm)
      # For this reason we're limiting each part of the unique subdomain
      #
      # The domain is made up of 3 parts, like: projectpath-namespacepath-randomstring
      # - project path: between 1 and 48 chars
      # - namespace path: when the project path has less than 48 chars,
      #   the namespace full path will be used to fill the value up to 48 chars
      # - random hexadecimal: to ensure a random value, the domain is then filled
      #   with a random hexadecimal value to complete 63 chars
      def generate
        domain = project_path.byteslice(0, PROJECT_PATH_LIMIT)

        # if the project_path has less than PROJECT_PATH_LIMIT chars,
        # fill the domain with the parent full_path up to 48 chars like:
        # projectpath-namespacepath
        if domain.length < PROJECT_PATH_LIMIT
          namespace_size = PROJECT_PATH_LIMIT - domain.length - 1
          domain.concat('-', namespace_path.byteslice(0, namespace_size))
        end

        # Complete the domain with random hexadecimal values util it is 63 chars long
        # PS.: SecureRandom.hex return an string twice the size passed as argument.
        domain.concat('-', SecureRandom.hex(SUBDOMAIN_LABEL_LIMIT - domain.length - 1))

        # Slugify ensures the format and size (63 chars) of the given string
        Gitlab::Utils.slugify(domain)
      end

      private

      attr_reader :project_path, :namespace_path
    end
  end
end
