require "em-websocket"
require "em-hiredis"
require "json"

EM.run do
  @channels = Hash.new
  EM::WebSocket.start(host: "0.0.0.0", port: "8080", debug: false) do |socket|
    socket.onopen do |handshake|
      channel = channel_for_socket(handshake)

      @redis = EM::Hiredis.connect("unix:///Users/phil/Projects/gdk-ce/redis/redis.socket")
      pubsub = @redis.pubsub
      pubsub.subscribe "todos.#{path(handshake)}"
      pubsub.on(:message) do |redis_channel, message|
        data = {
          channel: redis_channel.split(".").first,
          data: JSON.parse(message)
        }
        channel.push data.to_json
      end

      sid = channel.subscribe do |msg|
        socket.send msg
      end

      socket.onclose do
        pubsub.unsubscribe "todos.#{path(handshake)}"
        channel.unsubscribe(sid)
      end
    end
  end

  def path(handshake)
    handshake.path.split("/").last
  end

  def channel_for_socket(handshake)
    channel_path = path(handshake)
    @channels[channel_path] ||= EM::Channel.new
  end
end
