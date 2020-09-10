# frozen_string_literal: true

module Gitlab
  module StaticSiteEditor
    module Config
      class FileConfig
        def data
          merge_requests_illustration_path = ActionController::Base.helpers.image_path('illustrations/merge_requests.svg')
          {
            merge_requests_illustration_path: merge_requests_illustration_path
          }
        end
      end
    end
  end
end
