# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    # rubocop:disable Style/Documentation
    class RecalculateProjectAuthorizations
      def perform(user_ids)
        user_ids.each do |user_id|
          user = User.find_by(id: user_id)

          next unless user

          service = Users::RefreshAuthorizedProjectsService.new(
            user,
            incorrect_auth_found_callback:
              ->(project_id, access_level) do
                logger.info(message: 'Removing ProjectAuthorizations',
                            user_id: user.id,
                            project_id: project_id,
                            access_level: access_level)
              end,
            missing_auth_found_callback:
              ->(project_id, access_level) do
                logger.info(message: 'Creating ProjectAuthorizations',
                            user_id: user.id,
                            project_id: project_id,
                            access_level: access_level)
              end
          )

          service.execute
        end
      end

      private

      def logger
        @logger ||= Gitlab::BackgroundMigration::Logger.build
      end
    end
  end
end
