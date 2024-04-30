# frozen_string_literal: true

namespace :gitlab do
  namespace :two_factor do
    desc "GitLab | 2FA | Disable Two-factor authentication (2FA) for all users"
    task disable_for_all_users: :gitlab_environment do
      scope = User.with_two_factor
      count = scope.count

      if count > 0
        puts "This will disable 2FA for #{Rainbow(count.to_s).red} users..."

        begin
          ask_to_continue
          scope.find_each(&:disable_two_factor!)
          puts Rainbow("Successfully disabled 2FA for #{count} users.").green
        rescue Gitlab::TaskAbortedByUserError
          puts Rainbow("Quitting...").red
        end
      else
        puts Rainbow("There are currently no users with 2FA enabled.").yellow
      end
    end

    namespace :rotate_key do
      def rotator
        @rotator ||= Gitlab::OtpKeyRotator.new(ENV['filename'])
      end

      desc "GitLab | 2FA | Rotate Key | Encrypt user OTP secrets with a new encryption key"
      task apply: :environment do |t, args|
        rotator.rotate!(old_key: ENV['old_key'], new_key: ENV['new_key'])
      end

      desc "GitLab | 2FA | Rotate Key | Rollback to secrets encrypted with the old encryption key"
      task rollback: :environment do
        rotator.rollback!
      end
    end
  end
end
