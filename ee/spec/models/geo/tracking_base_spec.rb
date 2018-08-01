require 'spec_helper'

describe Geo::TrackingBase do
  it 'raises when Geo database is not configured' do
    allow(Gitlab::Geo).to receive(:geo_database_configured?).and_return(false)

    expect(described_class).not_to receive(:retrieve_connection)
    expect { described_class.connection }.to raise_error(Geo::TrackingBase::SecondaryNotConfigured)
  end

  it 'raises when Geo database is not found' do
    allow(Gitlab::Geo).to receive(:geo_database_configured?).and_return(true)
    allow(described_class).to receive(:retrieve_connection).and_raise(ActiveRecord::NoDatabaseError.new('not found'))

    expect(described_class).to receive(:retrieve_connection)
    expect { described_class.connection }.to raise_error(Geo::TrackingBase::SecondaryNotConfigured)
  end
end
