module Ci
  class HipChatNotifierWorker
    include Sidekiq::Worker

    def perform(message, options={})
      room   = options.delete('room')
      token  = options.delete('token')
      server = options.delete('server')
      name   = options.delete('service_name')
      client_opts = {
        api_version: 'v2',
        server_url: server
      }

      client = HipChat::Client.new(token, client_opts)
      client[room].send(name, message, options.symbolize_keys)
    end
  end
end
