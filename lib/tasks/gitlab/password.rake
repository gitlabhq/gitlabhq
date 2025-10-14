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

    # This is an alias for :check_hashes for backwards compatibility.
    desc "GitLab | Password | Check status of password salts on FIPS systems"
    task :fips_check_salts, [:print_usernames] => :environment do |t, args|
      alias_args = t.arg_names.map { |a| args[a] }
      Rake::Task['gitlab:password:check_hashes'].invoke(*alias_args)
    end

    desc "GitLab | Password | Check status of password hashes"
    task :check_hashes, [:print_usernames] => :environment do |_, args|
      message = "Active users with unmigrated hashes:"
      batch_size = 50
      count_total = 0
      count_unmigrated = 0

      puts Rainbow(message) if args.print_usernames

      User.active.each_batch(of: batch_size) do |user_batch|
        user_batch.each do |user|
          count_total += 1

          begin
            unless user.migrated_password?
              count_unmigrated += 1
              puts user.username if args.print_usernames
            end
          rescue StandardError => e
            puts("Error getting hash for user #{user.username}: #{e.message}")
            next
          end
        end
      end

      puts Rainbow("#{message} #{count_unmigrated} out of #{count_total} total users")
    end
  end
end
