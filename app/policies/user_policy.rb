class UserPolicy < BasePolicy
  def rules
    can! :read_user if @user || !restricted_public_level?

    if @user
      if @user.admin? || @subject == @user
        can! :destroy_user
      end

      cannot! :destroy_user if @subject.ghost?
    end
  end
end
