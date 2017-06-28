Rails.application.configure do |config|
  Warden::Manager.after_set_user do |user, auth, opts|
    Gitlab::Auth::UniqueIpsLimiter.limit_user!(user)
  end
end
