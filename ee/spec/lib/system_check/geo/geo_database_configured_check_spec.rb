require 'spec_helper'
require 'rake_helper'

describe SystemCheck::Geo::GeoDatabaseConfiguredCheck do
  before do
    silence_output
  end

  subject { described_class.new }

  describe '#multi_check' do
    it "checks database configuration" do
      stub_configuration_check(false)

      expect(subject).to receive(:try_fixing_it).with(described_class::WRONG_CONFIGURATION_MESSAGE)
      expect(subject.multi_check).to be_falsey
    end

    it "checks database configuration" do
      stub_configuration_check(true)
      stub_connection_state(false)

      expect(subject).to receive(:try_fixing_it).with(described_class::UNHEALTHY_CONNECTION_MESSAGE)

      expect(subject.multi_check).to be_falsey
    end

    it "checks table existence" do
      stub_configuration_check(true)
      stub_connection_state(true)
      stub_tables_existence(false)

      expect(subject).to receive(:try_fixing_it).with(described_class::NO_TABLES_MESSAGE)

      expect(subject.multi_check).to be_falsey
    end

    it "returns true when all checks passed" do
      stub_configuration_check(true)
      stub_connection_state(true)
      stub_tables_existence(true)

      expect(subject).not_to receive(:try_fixing_it)

      expect(subject.multi_check).to be_truthy
    end
  end

  def stub_configuration_check(state)
    expect(Gitlab::Geo).to receive(:geo_database_configured?).and_return(state)
  end

  def stub_connection_state(state)
    connection = double
    expect(connection).to receive(:active?).and_return(state)
    expect(::Geo::TrackingBase).to receive(:connection).and_return(connection)
  end

  def stub_tables_existence(state)
    expect(ActiveRecord::Migrator).to receive(:needs_migration?).and_return(!state)
  end
end
