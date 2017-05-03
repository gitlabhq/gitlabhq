# Adds logging for all Rack Attack blocks and throttling events.

ActiveSupport::Notifications.subscribe('rack.attack') do |name, start, finish, request_id, req|
  if [:throttle, :blacklist].include? req.env['rack.attack.match_type']
    Rails.logger.info("Rack_Attack: #{req.env['rack.attack.match_type']} #{req.ip} #{req.request_method} #{req.fullpath}")
  end
end
