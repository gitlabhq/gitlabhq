# frozen_string_literal: true
#
# Adds logging for all Rack Attack blocks and throttling events.

ActiveSupport::Notifications.subscribe('rack.attack') do |name, start, finish, request_id, req|
  if [:throttle, :blacklist].include? req.env['rack.attack.match_type']
    rack_attack_info = {
      message: 'Rack_Attack',
      env: req.env['rack.attack.match_type'],
      remote_ip: req.ip,
      request_method: req.request_method,
      path: req.fullpath
    }

    if %w(throttle_authenticated_api throttle_authenticated_web).include? req.env['rack.attack.matched']
      user_id = req.env['rack.attack.match_discriminator']
      user = User.find_by(id: user_id)

      rack_attack_info[:user_id] = user_id
      rack_attack_info[:username] = user.username unless user.nil?
    end

    Gitlab::AuthLogger.error(rack_attack_info)
  end
end
