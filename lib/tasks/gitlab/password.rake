# frozen_string_literal: true
namespace :gitlab do
  namespace :password do
    desc "GitLab | Password | Reset a user's password"
    task :reset, [:username] => :environment do |_, args|
      username = args[:username] || Gitlab::TaskHelpers.prompt('Enter username: ')
      abort('Username can not be empty.') if username.blank?

      user = User.find_by(username: username)
      abort("Unable to find user with username #{username}.") unless user

      password = Gitlab::TaskHelpers.prompt_for_password
      password_confirm = Gitlab::TaskHelpers.prompt_for_password('Confirm password: ')

      user.password = password
      user.password_confirmation = password_confirm
      user.password_automatically_set = false
      user.send_only_admin_changed_your_password_notification!

      unless user.save
        message = <<~EOF
          Unable to change password of the user with username #{username}.
          #{user.errors.full_messages.to_sentence}
        EOF

        abort(message)
      end

      puts "Password successfully updated for user with username #{username}."
    end
  end
end
