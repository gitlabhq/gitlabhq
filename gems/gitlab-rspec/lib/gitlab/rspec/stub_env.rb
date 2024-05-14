# frozen_string_literal: true

# Inspired by https://github.com/ljkbennett/stub_env/blob/master/lib/stub_env/helpers.rb
module StubENV
  # Stub ENV variables
  #
  # You can provide either a key and value as separate params or both in a Hash format
  #
  # Keys and values will always be converted to String, to comply with how ENV behaves
  #
  # @param key_or_hash [String, Hash<String,String>]
  # @param value [String]
  def stub_env(key_or_hash, value = nil)
    init_stub unless env_stubbed?

    if key_or_hash.is_a? Hash
      key_or_hash.each do |key, value|
        add_stubbed_value(key, ensure_env_type(value))
      end
    else
      add_stubbed_value key_or_hash, ensure_env_type(value)
    end
  end

  private

  STUBBED_KEY = '__STUBBED__'

  def add_stubbed_value(key, value)
    allow(ENV).to receive(:[]).with(key).and_return(value)
    allow(ENV).to receive(:key?).with(key).and_return(true)
    allow(ENV).to receive(:fetch).with(key) do |_|
      value || raise(KeyError, "key not found: \"#{key}\"")
    end
    allow(ENV).to receive(:fetch).with(key, anything) do |_, default_val|
      value || default_val
    end
  end

  def env_stubbed?
    ENV.fetch(STUBBED_KEY, false)
  end

  def init_stub
    allow(ENV).to receive(:[]).and_call_original
    allow(ENV).to receive(:key?).and_call_original
    allow(ENV).to receive(:fetch).and_call_original
    add_stubbed_value(STUBBED_KEY, true)
  end

  def ensure_env_type(value)
    value.nil? ? value : value.to_s
  end
end
