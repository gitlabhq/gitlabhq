# frozen_string_literal: true

module ActivityPub
  module Projects
    class ReleasesController < ApplicationController
      feature_category :release_orchestration

      before_action :enforce_payload, only: :inbox

      def index
        opts = {
          inbox: inbox_project_releases_url(@project),
          outbox: outbox_project_releases_url(@project)
        }

        render json: ActivityPub::ReleasesActorSerializer.new.represent(@project, opts)
      end

      def inbox
        service = inbox_service
        success = service ? service.execute : true

        response = { success: success }
        response[:errors] = service.errors unless success

        render json: response
      end

      def outbox
        serializer = ActivityPub::ReleasesOutboxSerializer.new.with_pagination(request, response)
        render json: serializer.represent(releases)
      end

      private

      def releases(params = {})
        ReleasesFinder.new(@project, current_user, params).execute
      end

      def enforce_payload
        return if payload

        head :unprocessable_entity
        false
      end

      def payload
        @payload ||= begin
          Gitlab::Json.parse(request.body.read)
        rescue JSON::ParserError
          nil
        end
      end

      def follow?
        payload['type'] == 'Follow'
      end

      def unfollow?
        undo = payload['type'] == 'Undo'
        object = payload['object']
        follow = object.present? && object.is_a?(Hash) && object['type'] == 'Follow'
        undo && follow
      end

      def inbox_service
        return ReleasesFollowService.new(project, payload) if follow?
        return ReleasesUnfollowService.new(project, payload) if unfollow?

        nil
      end
    end
  end
end
