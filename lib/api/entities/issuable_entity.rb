# frozen_string_literal: true

module API
  module Entities
    class IssuableEntity < Grape::Entity
      expose :id, :iid
      expose(:project_id) { |entity| entity&.project.try(:id) }
      expose :title, :description
      expose :state, :created_at, :updated_at

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
        BatchLoader.for(object).batch(key: [current_user, :issuable_metadata], replace_methods: false) do |models, loader, args|
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
