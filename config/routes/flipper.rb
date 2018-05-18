constraint = lambda { |request| request.env['warden'].authenticate? && request.env['warden'].user.admin? }
constraints constraint do
  mount Flipper::UI.app(Flipper), at: '/admin/flipper', as: :flipper
end
