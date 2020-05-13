# frozen_string_literal: true

# Returns smaller sized design images
module Projects
  module DesignManagement
    module Designs
      class ResizedImageController < Projects::DesignManagement::DesignsController
        include SendFileUpload

        before_action :validate_size!

        skip_before_action :default_cache_headers, only: :show

        def show
          relation = design.actions
          relation = relation.up_to_version(sha) if sha
          action = relation.most_recent.first

          return render_404 unless action

          # This controller returns a 404 if the  the `size` param
          # is not one of our specific sizes, so using `send` here is safe.
          uploader = action.public_send(:"image_#{size}") # rubocop:disable GitlabSecurity/PublicSend

          return render_404 unless uploader.file # The image has not been processed

          if stale?(etag: action.cache_key)
            workhorse_set_content_type!

            send_upload(uploader, attachment: design.filename)
          end
        end

        private

        def validate_size!
          render_404 unless ::DesignManagement::DESIGN_IMAGE_SIZES.include?(size)
        end

        def size
          params[:id]
        end
      end
    end
  end
end
