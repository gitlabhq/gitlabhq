# frozen_string_literal: true

Circuitbox.configure do |config|
  config.default_circuit_store = Gitlab::CircuitBreaker::Store.new
  config.default_notifier = Gitlab::CircuitBreaker::Notifier.new
end
