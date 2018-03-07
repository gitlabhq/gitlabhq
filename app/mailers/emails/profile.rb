module Emails
  module Profile
    def new_user_email(user_id, token = nil)
      @current_user = @user = User.find(user_id)
      @target_url = user_url(@user)
      @token = token
      mail(to: @user.notification_email, subject: subject("Account was created for you"))
    end

    def new_ssh_key_email(key_id)
      @key = Key.find_by(id: key_id)

      return unless @key

      @current_user = @user = @key.user
      @target_url = user_url(@user)
      mail(to: @user.notification_email, subject: subject("SSH key was added to your account"))
    end

    def new_gpg_key_email(gpg_key_id)
      @gpg_key = GpgKey.find_by(id: gpg_key_id)

      return unless @gpg_key

      @current_user = @user = @gpg_key.user
      @target_url = user_url(@user)
      mail(to: @user.notification_email, subject: subject("GPG key was added to your account"))
    end
  end
end
