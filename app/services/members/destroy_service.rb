module Members
  class DestroyService < BaseService
    attr_accessor :member, :current_user

    def initialize(member, user)
      @member, @current_user = member, user
    end

    def execute
      if can?(current_user, "destroy_#{member.type.underscore}".to_sym, member)
        member.destroy

        if member.request? && member.user != current_user
          notification_service.decline_access_request(member)
        end
      end

      member
    end

    private

    def abilities
      Ability.abilities
    end

    def can?(object, action, subject)
      abilities.allowed?(object, action, subject)
    end

    def notification_service
      NotificationService.new
    end
  end
end
