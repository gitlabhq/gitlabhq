require 'prometheus/client'
require 'singleton'

class PromService
  include Singleton

  attr_reader :login

  def initialize
    @prometheus = Prometheus::Client.registry

    @login = Prometheus::Client::Counter.new(:login, 'Login counter')
    @prometheus.register(@login)
  end
end
