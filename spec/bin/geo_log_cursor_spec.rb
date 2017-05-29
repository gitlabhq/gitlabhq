require 'spec_helper'

load File.expand_path('../../bin/geo_log_cursor', __dir__)

describe 'scripts/geo_log_cursor' do
  describe GeoLogCursorOptionParser do
    it 'parses -f and --full-scan' do
      %w[-f --full-scan].each do |flag|
        options = described_class.parse(%W[foo #{flag} bar])

        expect(options[:full_scan]).to eq true
      end
    end
  end
end
