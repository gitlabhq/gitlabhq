# frozen_string_literal: true

require 'spec_helper'

RSpec.describe EventForward::Logger, feature_category: :product_analytics do
  subject(:logger) { described_class.new('/dev/null') }

  it_behaves_like 'a json logger', {}

  describe '#file_name_noext' do
    it 'returns log file name without extension' do
      expect(described_class.file_name_noext).to eq('event_collection')
    end
  end
end
