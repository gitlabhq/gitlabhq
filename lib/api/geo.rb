# frozen_string_literal: true

module API
  class Geo < ::API::Base
    feature_category :geo_replication

    helpers do
      # Overridden in EE
      def geo_proxy_response
        {}
      end
    end

    resource :geo do
      # Workhorse calls this to determine if it is a Geo site that should proxy
      # requests. Workhorse doesn't know if it's in a FOSS/EE context.
      get '/proxy' do
        require_gitlab_workhorse!

        status :ok
        content_type Gitlab::Workhorse::INTERNAL_API_CONTENT_TYPE

        geo_proxy_response
      end
    end
  end
end

API::Geo.prepend_mod
