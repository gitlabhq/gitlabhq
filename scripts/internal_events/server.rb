# frozen_string_literal: true

require 'webrick'
require 'json'
require 'base64'

class Server
  attr_accessor :events

  def initialize
    port = Gitlab::Tracking::Destinations::SnowplowMicro.new.uri.port
    @server = WEBrick::HTTPServer.new Port: port, Logger: WEBrick::Log.new(nil, WEBrick::BasicLog::ERROR)

    trap 'INT' do
      @server.shutdown
    end

    @events = []
  end

  def start
    @server.mount_proc '/i' do |req, res|
      @events << extract_event(req.query)
      res.status = 200
    end

    @server.mount_proc '/micro/good' do |_req, res|
      res.status = 200
      res.body = JSON.dump(@events)
    end

    @server.start
  end

  def stop
    @server.shutdown
  end

  private

  def extract_event(query)
    {
      event: {
        se_category: query['se_ca'],
        se_action: query['se_ac'],
        collector_tstamp: query['dtm'],
        label: query['se_la'],
        property: query['se_pr'],
        value: query['se_va'],
        contexts: JSON.parse(Base64.decode64(query['cx']))
      },
      rawEvent: { parameters: query }
    }
  end
end
