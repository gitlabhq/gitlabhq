# frozen_string_literal: true

module Users
  class SetStatusService
    include Gitlab::Allowable

    attr_reader :current_user, :target_user, :params

    def initialize(current_user, params)
      @current_user = current_user
      @params = params.dup
      @target_user = params.delete(:user) || current_user
    end

    def execute
      return false unless can?(current_user, :update_user_status, target_user)

      if status_cleared?
        remove_status
      else
        set_status
      end
    end

    private

    def set_status
      params[:emoji] = UserStatus::DEFAULT_EMOJI if params[:emoji].blank?
      params[:availability] = UserStatus.availabilities[:not_set] unless new_user_availability

      user_status.update(params)
    end

    def remove_status
      UserStatus.delete(target_user.id)
    end

    def user_status
      target_user.status || target_user.build_status
    end

    def status_cleared?
      params[:emoji].blank? &&
        params[:message].blank? &&
        (new_user_availability.blank? || new_user_availability == UserStatus.availabilities[:not_set])
    end

    def new_user_availability
      UserStatus.availabilities[params[:availability]]
    end
  end
end
