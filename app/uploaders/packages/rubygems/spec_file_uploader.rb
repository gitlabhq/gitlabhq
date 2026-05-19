# frozen_string_literal: true

module Packages
  module Rubygems
    class SpecFileUploader < Packages::BaseMetadataCacheUploader
      def filename
        model.file_name
      end
    end
  end
end
