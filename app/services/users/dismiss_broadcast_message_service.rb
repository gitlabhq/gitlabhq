# frozen_string_literal: true

module Users
  class DismissBroadcastMessageService
    def initialize(current_user:, params: {})
      @current_user = current_user
      @params = params
    end

    def execute
      result = dismissal.tap do |record|
        record.expires_at = params[:expires_at]
      end.save

      return ServiceResponse.success if result

      ServiceResponse.error(message: _('Failed to save dismissal'))
    end

    private

    attr_reader :current_user, :params

    def dismissal
      Users::BroadcastMessageDismissal.find_or_initialize_dismissal(current_user, params[:broadcast_message_id])
    end
  end
end
