require 'spec_helper'

describe Gitlab::Geo::HealthCheck, :geo do
  set(:secondary) { create(:geo_node) }

  subject { described_class }

  before do
    allow(Gitlab::Geo).to receive(:current_node).and_return(secondary)
  end

  describe '.perform_checks' do
    it 'returns a string if database is not fully migrated' do
      allow(described_class).to receive(:geo_database_configured?).and_return(true)
      allow(described_class).to receive(:database_secondary?).and_return(true)
      allow(described_class).to receive(:get_database_version).and_return('20170101')
      allow(described_class).to receive(:get_migration_version).and_return('20170201')
      allow(described_class).to receive(:streaming_active?).and_return(true)

      message = subject.perform_checks

      expect(message).to include('Current Geo database version (20170101) does not match latest migration (20170201)')
      expect(message).to include('gitlab-rake geo:db:migrate')
    end

    it 'returns an empty string when not running on a secondary node' do
      allow(Gitlab::Geo).to receive(:secondary?) { false }

      expect(subject.perform_checks).to be_blank
    end

    it 'returns an error when database is not configured for streaming replication' do
      allow(Gitlab::Geo).to receive(:configured?) { true }
      allow(Gitlab::Database).to receive(:postgresql?) { true }
      allow(described_class).to receive(:database_secondary?) { false }

      expect(subject.perform_checks).not_to be_blank
    end

    it 'returns an error when streaming replication is not working' do
      allow(Gitlab::Geo).to receive(:configured?) { true }
      allow(Gitlab::Database).to receive(:postgresql?) { true }
      allow(described_class).to receive(:database_secondary?) { false }

      expect(subject.perform_checks).to include('not configured for streaming replication')
    end

    it 'returns an error when configuration file is missing for tracking DB' do
      allow(Rails.configuration).to receive(:respond_to?).with(:geo_database) { false }

      expect(subject.perform_checks).to include('database configuration file is missing')
    end

    it 'returns an error when Geo database version does not match the latest migration version' do
      allow(described_class).to receive(:database_secondary?).and_return(true)
      allow(subject).to receive(:get_database_version) { 1 }
      allow(described_class).to receive(:streaming_active?).and_return(true)

      expect(subject.perform_checks).to match(/Current Geo database version \([0-9]+\) does not match latest migration \([0-9]+\)/)
    end

    it 'returns an error when latest migration version does not match the Geo database version' do
      allow(described_class).to receive(:database_secondary?).and_return(true)
      allow(subject).to receive(:get_migration_version) { 1 }
      allow(described_class).to receive(:streaming_active?).and_return(true)

      expect(subject.perform_checks).to match(/Current Geo database version \([0-9]+\) does not match latest migration \([0-9]+\)/)
    end

    it 'returns an error when streaming is not active and Postgresql supports pg_stat_wal_receiver' do
      allow(Gitlab::Database).to receive(:pg_stat_wal_receiver_supported?).and_return(true)
      allow(described_class).to receive(:database_secondary?).and_return(true)
      allow(described_class).to receive(:streaming_active?).and_return(false)

      expect(subject.perform_checks).to match(/The Geo node does not appear to be replicating the database from the primary node/)
    end

    it 'returns an error when streaming is not active and Postgresql does not support pg_stat_wal_receiver' do
      allow(Gitlab::Database).to receive(:pg_stat_wal_receiver_supported?).and_return(false)
      allow(described_class).to receive(:database_secondary?).and_return(true)
      allow(described_class).to receive(:streaming_active?).and_return(false)

      expect(subject.perform_checks).to be_empty
    end

    it 'returns an error when FDW is disabled' do
      allow(described_class).to receive(:database_secondary?) { true }
      allow(described_class).to receive(:streaming_active?) { true }

      allow(Gitlab::Geo::Fdw).to receive(:enabled?) { false }

      expect(subject.perform_checks).to match(/The Geo database is not configured to use Foreign Data Wrapper/)
    end

    it 'returns an error when FDW remote table is not in sync but has same amount of tables' do
      allow(described_class).to receive(:database_secondary?) { true }
      allow(described_class).to receive(:streaming_active?) { true }

      allow(Gitlab::Geo::Fdw).to receive(:fdw_up_to_date?) { false }
      allow(Gitlab::Geo::Fdw).to receive(:count_tables_match?) { true }

      expect(subject.perform_checks).to match(/The Geo database has an outdated FDW remote schema\./)
    end

    it 'returns an error when FDW remote table is not in sync and has same different amount of tables' do
      allow(described_class).to receive(:database_secondary?) { true }
      allow(described_class).to receive(:streaming_active?) { true }

      allow(Gitlab::Geo::Fdw).to receive(:fdw_up_to_date?) { false }
      allow(Gitlab::Geo::Fdw).to receive(:count_tables_match?) { false }

      expect(subject.perform_checks).to match(/The Geo database has an outdated FDW remote schema\. It contains [0-9]+ of [0-9]+ expected tables/)
    end
  end

  describe 'MySQL checks' do
    it 'raises an error' do
      allow(Gitlab::Database).to receive(:postgresql?) { false }

      expect { subject.perform_checks }.to raise_error(NotImplementedError)
    end
  end
end
