module Emails
  module Profile
    def new_user_email(user_id, token = nil)
      @current_user = @user = User.find(user_id)
      @target_url = user_url(@user)
      @token = token
      mail(to: @user.notification_email, subject: subject("已为你创建账户"))
    end

    def new_email_email(email_id)
      @email = Email.find(email_id)
      @current_user = @user = @email.user
      mail(to: @user.notification_email, subject: subject("你的账户已添加邮箱"))
    end

    def new_ssh_key_email(key_id)
      @key = Key.find_by_id(key_id)

      return unless @key

      @current_user = @user = @key.user
      @target_url = user_url(@user)
      mail(to: @user.notification_email, subject: subject("你的账户已添加 SSH 秘钥"))
    end
  end
end
