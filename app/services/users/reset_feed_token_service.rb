# frozen_string_literal: true

module Users
  class ResetFeedTokenService < BaseService
    VALID_SOURCES = %i[self group_token_revocation_service api_admin_token].freeze

    def initialize(current_user = nil, user: nil, source: nil)
      @current_user = current_user
      @user = user
      @source = source

      @source = :self if @current_user && !@source

      raise ArgumentError unless user
      raise ArgumentError unless VALID_SOURCES.include?(@source)
    end

    def execute
      return ServiceResponse.error(message: s_('Not permitted to reset user feed token')) unless reset_permitted?

      result = Users::UpdateService.new(current_user, user: user).execute(&:reset_feed_token!)
      if result[:status] == :success
        log_event
        ServiceResponse.success(message: success_message)
      else
        ServiceResponse.error(message: error_message)
      end
    end

    private

    attr_reader :user, :source

    def error_message
      s_('Profiles|Feed token could not be reset')
    end

    def success_message
      s_('Profiles|Feed token was successfully reset')
    end

    def reset_permitted?
      case source
      when :self
        Ability.allowed?(current_user, :update_user, user)
      when :group_token_revocation_service, :api_admin_token
        true
      end
    end

    def log_event
      Gitlab::AppLogger.info(
        class: self.class.name,
        message: "User Feed Token Reset",
        source: source,
        reset_by: current_user&.username,
        reset_for: user.username,
        user_id: user.id)
    end
  end
end
