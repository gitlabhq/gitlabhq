# frozen_string_literal: true

module Packages
  module Debian
    class FindOrCreatePackageService < ::Packages::CreatePackageService
      include Gitlab::Utils::StrongMemoize

      def execute
        package = project.packages
                         .debian
                         .with_name(params[:name])
                         .with_version(params[:version])
                         .with_debian_codename_or_suite(params[:distribution_name])
                         .not_pending_destruction
                         .first

        package ||= create_package!(
          :debian,
          debian_publication_attributes: { distribution_id: distribution.id }
        )

        ServiceResponse.success(payload: { package: package })
      end

      private

      def distribution
        strong_memoize(:distribution) do
          Packages::Debian::DistributionsFinder.new(
            project,
            codename_or_suite: params[:distribution_name]
          ).execute.last!
        end
      end
    end
  end
end
