# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::PipelineSchedulesHelper, :aggregate_failures do
  describe '#timezone_data' do
    subject { helper.timezone_data }

    it 'matches schema' do
      expect(subject).not_to be_empty
      subject.each_with_index do |timzone_hash, i|
        expect(timzone_hash.keys).to contain_exactly(:name, :offset, :identifier), "Failed at index #{i}"
      end
    end

    it 'formats for display' do
      first_timezone = ActiveSupport::TimeZone.all[0]

      expect(subject[0][:name]).to eq(first_timezone.name)
      expect(subject[0][:offset]).to eq(first_timezone.now.utc_offset)
      expect(subject[0][:identifier]).to eq(first_timezone.tzinfo.identifier)
    end
  end
end
