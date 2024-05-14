# frozen_string_literal: true

require 'webrick'

module Gitlab
  module HealthChecks
    class Server < Daemon
      def initialize(address:, port:, **options)
        super(**options)

        @address = address
        @port = port
      end

      private

      def start_working
        @server = ::WEBrick::HTTPServer.new(
          Port: @port, BindAddress: @address, AccessLog: []
        )
        @server.mount '/', Rack::Handler::WEBrick, rack_app

        true
      end

      def run_thread
        @server&.start
      rescue IOError
        # ignore forcibily closed servers
      end

      def stop_working
        if @server
          # we close sockets if thread is not longer running
          # this happens, when the process forks
          if thread.alive?
            @server.shutdown
          else
            @server.listeners.each(&:close)
          end
        end

        @server = nil
      end

      def rack_app
        readiness = new_probe
        liveness = new_probe

        Rack::Builder.app do
          use Rack::Deflater
          use HealthChecks::Middleware, readiness, liveness
          run ->(env) { [404, {}, ['']] }
        end
      end

      def new_probe
        ::Gitlab::HealthChecks::Probes::Collection.new
      end
    end
  end
end
