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

    desc "GitLab | Password | Check status of password salts on FIPS systems"
    task :fips_check_salts, [:print_usernames] => :environment do |_, args|
      abort Rainbow('This command is only available on FIPS instances').red unless Gitlab::FIPS.enabled?

      message = "Active users with unmigrated salts:"
      batch_size = 50
      min_salt_len = 64
      count_total = 0
      count_unmigrated = 0

      puts Rainbow(message) if args.print_usernames

      User.active.each_batch(of: batch_size) do |user_batch|
        user_batch.each do |user|
          count_total += 1

          begin
            hash = user.encrypted_password
            salt_len = Devise::Pbkdf2Encryptable::Encryptors::Pbkdf2Sha512
              .split_digest(hash)[:salt].length
          rescue StandardError => e
            puts("Error getting salt for user #{user.username}: #{e.message}")
            next
          end

          if salt_len < min_salt_len
            puts user.username if args.print_usernames
            count_unmigrated += 1
          end
        end
      end

      puts Rainbow("#{message} #{count_unmigrated} out of #{count_total} total users")
    end
  end
end
