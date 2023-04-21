# frozen_string_literal: true

Circuitbox.configure do |config|
  config.default_circuit_store = Circuitbox::MemoryStore.new
  config.default_notifier = GitLab::CircuitBreaker::Notifier.new
end
