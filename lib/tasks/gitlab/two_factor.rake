namespace :gitlab do
  namespace :two_factor do
    desc "GitLab | Disable Two-factor authentication (2FA) for all users"
    task disable_for_all_users: :environment do
      scope = User.with_two_factor
      count = scope.count

      if count > 0
        puts "This will disable 2FA for #{count.to_s.red} users..."

        begin
          ask_to_continue
          scope.find_each(&:disable_two_factor!)
          puts "Successfully disabled 2FA for #{count} users.".green
        rescue Gitlab::TaskAbortedByUserError
          puts "Quitting...".red
        end
      else
        puts "There are currently no users with 2FA enabled.".yellow
      end
    end
  end
end
