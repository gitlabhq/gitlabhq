# frozen_string_literal: true

module API
  module Entities
    class IssuableEntity < Grape::Entity
      expose :id, documentation: { type: 'integer', example: 84 }
      expose :iid, documentation: { type: 'integer', example: 14 }
      expose :project_id, documentation: { type: 'integer', example: 4 } do |entity|
        entity&.project.try(:id)
      end
      expose :title, documentation: { type: 'string', example: 'Impedit et ut et dolores vero provident ullam est' }
      expose :description, documentation: { type: 'string', example: 'Repellendus impedit et vel velit dignissimos.' }
      expose :state, documentation: { type: 'string', example: 'closed' }
      expose :created_at, documentation: { type: 'dateTime', example: '2022-08-17T12:46:35.053Z' }
      expose :updated_at, documentation: { type: 'dateTime', example: '2022-11-14T17:22:01.470Z' }

      def presented
        lazy_issuable_metadata

        super
      end

      def issuable_metadata
        options.dig(:issuable_metadata, object.id) || lazy_issuable_metadata
      end

      protected

      # This method will preload the `issuable_metadata` for the current
      # entity according to the current top-level entity options, such
      # as the current_user.
      def lazy_issuable_metadata
        BatchLoader.for(object).batch(key: [current_user, :issuable_metadata]) do |models, loader, args|
          current_user = args[:key].first

          issuable_metadata = Gitlab::IssuableMetadata.new(current_user, models)
          metadata_by_id = issuable_metadata.data

          models.each do |issuable|
            loader.call(issuable, metadata_by_id[issuable.id])
          end
        end
      end

      private

      def current_user
        options[:current_user]
      end
    end
  end
end
