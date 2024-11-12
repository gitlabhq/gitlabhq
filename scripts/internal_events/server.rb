# frozen_string_literal: true

require 'webrick'
require 'json'
require 'base64'

class Server
  attr_accessor :events

  def initialize
    port = Gitlab::Tracking::Destinations::SnowplowMicro.new.uri.port
    @server = WEBrick::HTTPServer.new Port: port,
      Logger: WEBrick::Log.new(nil, WEBrick::BasicLog::ERROR),
      RequestCallback: ->(_req, res) {
        res.header['Access-Control-Allow-Credentials'] = 'true'
        res.header['Access-Control-Allow-Headers'] = 'Content-Type'
        res.header['Access-Control-Allow-Origin'] = Gitlab.config.gitlab.url
      }

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

    @server.mount_proc '/com.snowplowanalytics.snowplow/tp2' do |req, res|
      JSON.parse(req.body)['data'].each do |query|
        next unless query['e'] == "se"

        @events << extract_event(query)
      end

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
        se_label: query['se_la'],
        se_property: query['se_pr'],
        se_value: query['se_va'],
        contexts: (JSON.parse(Base64.decode64(query['cx'])) if query['cx'])
      },
      rawEvent: { parameters: query }
    }
  end
end
