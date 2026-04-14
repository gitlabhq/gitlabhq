# frozen_string_literal: true

RSpec.describe Gitlab::Database::DataIsolation::Configuration do
  subject(:config) { described_class.new }

  describe "#current_sharding_key_value" do
    it "defaults to a lambda returning nil for any sharding key" do
      expect(config.current_sharding_key_value.call(:organizations)).to be_nil
    end

    it "can be configured" do
      config.current_sharding_key_value = ->(_sk) { 42 }

      expect(config.current_sharding_key_value.call(:organizations)).to eq(42)
    end
  end

  describe "#sharding_key_map" do
    it "defaults to an empty hash" do
      expect(config.sharding_key_map).to eq({})
    end

    it "can be configured" do
      config.sharding_key_map = { 'projects' => { 'organization_id' => :organizations } }

      expect(config.sharding_key_map).to eq({ 'projects' => { 'organization_id' => :organizations } })
    end
  end

  describe "#on_stats" do
    it "defaults to nil" do
      expect(config.on_stats).to be_nil
    end

    it "can be configured" do
      callback = ->(stats) { stats }
      config.on_stats = callback

      expect(config.on_stats).to eq(callback)
    end
  end

  describe "#on_error" do
    it "defaults to nil" do
      expect(config.on_error).to be_nil
    end

    it "can be configured" do
      callback = ->(sql, _error) { sql }
      config.on_error = callback

      expect(config.on_error).to eq(callback)
    end
  end
end

RSpec.describe Gitlab::Database::DataIsolation do
  describe ".configure" do
    it "yields the configuration" do
      described_class.configure do |config|
        config.current_sharding_key_value = ->(_sk) { 1 }
      end

      expect(described_class.configuration.current_sharding_key_value.call(:organizations)).to eq(1)
    end
  end

  describe ".reset_configuration!" do
    it "resets to defaults" do
      described_class.configure do |config|
        config.current_sharding_key_value = ->(_sk) { 99 }
      end

      described_class.reset_configuration!

      expect(described_class.configuration.current_sharding_key_value.call(:organizations)).to be_nil
    end
  end

  describe ".install!" do
    it "prepends the Arel query transformer with ActiveRecord" do
      expect(ActiveRecord::Relation).to receive(:prepend).with(
        Gitlab::Database::DataIsolation::Strategies::Arel::ActiveRecordExtension
      )

      described_class.install!
    end
  end
end
