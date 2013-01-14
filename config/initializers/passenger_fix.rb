if defined?(PhusionPassenger)

  # When you're using Passenger with smart-lv2 (default) or smart spawn method,
  # Resque doesn't recognize that it has been forked and should re-establish
  # Redis connection. You can see this error message in log:
  #   Redis::InheritedError, Tried to use a connection from a child process 
  #   without reconnecting. You need to reconnect to Redis after forking.
  # 
  # This solution is based on 
  # https://github.com/redis/redis-rb/wiki/redis-rb-on-Phusion-Passenger
  #
  PhusionPassenger.on_event(:starting_worker_process) do |forked|
    # if we're in smart spawning mode, reconnect to Redis
    Resque.redis.client.reconnect if forked
  end
end
