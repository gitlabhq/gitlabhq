# frozen_string_literal: true

module Packages
  module Debian
    class FindOrCreatePackageService < ::Packages::CreatePackageService
      include Gitlab::Utils::StrongMemoize

      def execute
        packages = project.packages
                          .existing_debian_packages_with(name: params[:name], version: params[:version])

        package = packages.with_debian_codename_or_suite(params[:distribution_name]).first

        unless package
          package_in_other_distribution = packages.first

          if package_in_other_distribution
            raise ArgumentError, "Debian package #{params[:name]} #{params[:version]} exists " \
                                 "in distribution #{package_in_other_distribution.debian_distribution.codename}"
          end
        end

        package ||= create_package!(
          :debian,
          debian_publication_attributes: { distribution_id: distribution.id }
        )

        ServiceResponse.success(payload: { package: package })
      end

      private

      def distribution
        Packages::Debian::DistributionsFinder.new(
          project,
          codename_or_suite: params[:distribution_name]
        ).execute.last!
      end
      strong_memoize_attr :distribution
    end
  end
end
