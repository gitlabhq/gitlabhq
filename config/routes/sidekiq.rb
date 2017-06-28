constraint = lambda { |request| request.env['warden'].authenticate? && request.env['warden'].user.admin? }
constraints constraint do
  mount Sidekiq::Web, at: '/admin/sidekiq', as: :sidekiq
end
