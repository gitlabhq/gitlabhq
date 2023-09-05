# frozen_string_literal: true

module ActivityPub
  module Projects
    class ReleasesController < ApplicationController
      feature_category :release_orchestration

      def index
        opts = {
          inbox: nil,
          outbox: outbox_project_releases_url(@project)
        }

        render json: ActivityPub::ReleasesActorSerializer.new.represent(@project, opts)
      end

      def outbox
        serializer = ActivityPub::ReleasesOutboxSerializer.new.with_pagination(request, response)
        render json: serializer.represent(releases)
      end

      private

      def releases(params = {})
        ReleasesFinder.new(@project, current_user, params).execute
      end
    end
  end
end
