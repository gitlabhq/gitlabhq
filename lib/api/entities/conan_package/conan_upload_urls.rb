# frozen_string_literal: true

module API
  module Entities
    module ConanPackage
      class ConanUploadUrls < Grape::Entity
        expose :upload_urls, merge: true
      end
    end
  end
end
