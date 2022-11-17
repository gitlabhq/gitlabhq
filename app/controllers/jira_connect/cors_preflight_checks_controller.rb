# frozen_string_literal: true

module JiraConnect
  class CorsPreflightChecksController < ApplicationController
    feature_category :integrations

    skip_before_action :verify_atlassian_jwt!
    before_action :set_cors_headers

    def index
      return render_404 unless allow_cors_request?

      render plain: '', content_type: 'text/plain'
    end
  end
end
