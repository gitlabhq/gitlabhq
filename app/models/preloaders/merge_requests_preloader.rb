# frozen_string_literal: true

module Preloaders
  class MergeRequestsPreloader
    attr_reader :merge_requests

    def initialize(merge_requests)
      @merge_requests = merge_requests
    end

    def execute
      preloader = ActiveRecord::Associations::Preloader.new
      preloader.preload(merge_requests, { target_project: [:project_feature] })
      merge_requests.each do |merge_request|
        merge_request.lazy_upvotes_count
      end
    end
  end
end
