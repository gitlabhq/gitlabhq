# frozen_string_literal: true

module MembersDestroyer
  class UnassignIssuablesWorker
    include ApplicationWorker

    sidekiq_options retry: 3

    ENTITY_TYPES = %w(Group Project).freeze

    queue_namespace :unassign_issuables
    feature_category :authentication_and_authorization

    idempotent!

    def perform(user_id, entity_id, entity_type)
      unless ENTITY_TYPES.include?(entity_type)
        logger.error(
          message: "#{entity_type} is not a supported entity.",
          entity_type: entity_type,
          entity_id: entity_id,
          user_id: user_id
        )

        return
      end

      user = User.find(user_id)
      entity = entity_type.constantize.find(entity_id)

      ::Members::UnassignIssuablesService.new(user, entity).execute
    end
  end
end
