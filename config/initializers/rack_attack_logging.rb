# frozen_string_literal: true
#
# Adds logging for all Rack Attack blocks and throttling events.

ActiveSupport::Notifications.subscribe(/rack_attack/) do |name, start, finish, request_id, payload|
  req = payload[:request]

  case req.env['rack.attack.match_type']
  when :throttle, :blocklist, :track
    rack_attack_info = {
      message: 'Rack_Attack',
      env: req.env['rack.attack.match_type'],
      remote_ip: req.ip,
      request_method: req.request_method,
      path: req.fullpath,
      matched: req.env['rack.attack.matched']
    }

    throttles_with_user_information = [
      :throttle_authenticated_api,
      :throttle_authenticated_web,
      :throttle_authenticated_protected_paths_api,
      :throttle_authenticated_protected_paths_web
    ]

    if throttles_with_user_information.include? req.env['rack.attack.matched'].to_sym
      user_id = req.env['rack.attack.match_discriminator']
      user = User.find_by(id: user_id)

      rack_attack_info[:user_id] = user_id
      rack_attack_info['meta.user'] = user.username unless user.nil?
    end

    Gitlab::AuthLogger.error(rack_attack_info)
  when :safelist
    Gitlab::Instrumentation::Throttle.safelist = req.env['rack.attack.matched']
  end
end
