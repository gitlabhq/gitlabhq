# frozen_string_literal: true

module Packages
  module Helm
    class MetadataCacheUploader < Packages::BaseMetadataCacheUploader
      FILENAME = 'index.yaml'

      def filename
        FILENAME
      end
    end
  end
end
