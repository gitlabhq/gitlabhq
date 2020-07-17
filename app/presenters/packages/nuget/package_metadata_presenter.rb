# frozen_string_literal: true

module Packages
  module Nuget
    class PackageMetadataPresenter
      include Packages::Nuget::PresenterHelpers

      def initialize(package)
        @package = package
      end

      def json_url
        json_url_for(@package)
      end

      def archive_url
        archive_url_for(@package)
      end

      def catalog_entry
        catalog_entry_for(@package)
      end
    end
  end
end
