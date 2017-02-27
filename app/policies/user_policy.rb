class UserPolicy < BasePolicy
  include Gitlab::CurrentSettings

  def rules
    can! :read_user if @user || !restricted_public_level?

    if @user
      if @user.admin? || @subject == @user
        can! :destroy_user
      end

      cannot! :destroy_user if @subject.ghost?
    end
  end

  def restricted_public_level?
    current_application_settings.restricted_visibility_levels.include?(Gitlab::VisibilityLevel::PUBLIC)
  end
end
