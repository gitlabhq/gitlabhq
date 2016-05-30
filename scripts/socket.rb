require "em-websocket"
require "em-hiredis"
require "json"

EM.run do
  @channels = Hash.new
  @redis = EM::Hiredis.connect("unix://#{File.expand_path('..')}/redis/redis.socket")
  pubsub = @redis.pubsub
  pubsub.subscribe "todos"
  pubsub.on(:message) do |redis_channel, message|
    message = JSON.parse(message)
    data = {
      channel: redis_channel,
      data: message
    }

    if redis_channel == "todos"
      channel = @channels[message["user_id"].to_s]
      channel[:channel].push data.to_json
    end
  end

  EM::WebSocket.start(host: "0.0.0.0", port: "8080", debug: false) do |socket|
    socket.onopen do |handshake|
      channel = channel_for_socket(handshake)

      sid = channel[:channel].subscribe do |msg|
        socket.send msg
      end

      socket.onclose do
        channel[:channel].unsubscribe(sid)
        @channels.delete(path(handshake))
      end
    end
  end

  def path(handshake)
    handshake.path.split("/").last
  end

  def channel_for_socket(handshake)
    channel_path = path(handshake)
    @channels[channel_path] ||= {
      channel: EM::Channel.new,
      user_id: channel_path,
      subscribed: ['todos']
    }
  end
end
