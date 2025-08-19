# frozen_string_literal: true

module Packages
  module Npm
    class MetadataCacheUploader < Packages::BaseMetadataCacheUploader
      FILENAME = 'metadata.json'

      def filename
        FILENAME
      end
    end
  end
end
