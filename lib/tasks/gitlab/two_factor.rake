namespace :gitlab do
  namespace :two_factor do
    desc "GitLab | Disable Two-factor authentication (2FA) for all users"
    task disable_for_all_users: :environment do
      User.with_two_factor.find_each do |user|
        user.disable_two_factor!
      end
    end
  end
end
