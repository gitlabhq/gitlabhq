# frozen_string_literal: true

# Returns full-size design images
module Projects
  module DesignManagement
    module Designs
      class RawImagesController < Projects::DesignManagement::DesignsController
        include SendsBlob

        def show
          blob = design_repository.blob_at(ref, design.full_path)

          send_blob(design_repository, blob, inline: false, allow_caching: project.public?)
        end

        private

        def design_repository
          @design_repository ||= project.design_repository
        end

        def ref
          sha || design_repository.root_ref
        end
      end
    end
  end
end
