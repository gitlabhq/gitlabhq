# frozen_string_literal: true

module MembersDestroyer
  class UnassignIssuablesWorker
    include ApplicationWorker

    data_consistency :always

    sidekiq_options retry: 3

    ENTITY_TYPES = %w[Group Project].freeze

    queue_namespace :unassign_issuables
    feature_category :user_management

    idempotent!

    def perform(user_id, entity_id, entity_type, requesting_user_id)
      unless ENTITY_TYPES.include?(entity_type)
        logger.error(
          message: "#{entity_type} is not a supported entity.",
          entity_type: entity_type,
          entity_id: entity_id,
          user_id: user_id,
          requesting_user_id: requesting_user_id
        )

        return
      end

      if requesting_user_id.nil?
        logger.error(
          message: "requesting_user_id is nil.",
          entity_type: entity_type,
          entity_id: entity_id,
          user_id: user_id,
          requesting_user_id: requesting_user_id
        )

        return
      end

      requesting_user = User.find(requesting_user_id)
      user = User.find(user_id)
      entity = entity_type.constantize.find(entity_id)

      ::Members::UnassignIssuablesService.new(user, entity, requesting_user).execute
    end
  end
end
