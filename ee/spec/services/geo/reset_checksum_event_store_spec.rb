# frozen_string_literal: true

require 'spec_helper'

describe Geo::ResetChecksumEventStore do
  include EE::GeoHelpers

  set(:project) { create(:project) }
  set(:secondary_node) { create(:geo_node) }

  subject { described_class.new(project) }

  describe '#create!' do
    it_behaves_like 'a Geo event store', Geo::ResetChecksumEvent

    context 'when running on a primary node' do
      before do
        stub_primary_node
      end

      it 'tracks the project that checksum must be wiped' do
        subject.create!

        expect(Geo::ResetChecksumEvent.last).to have_attributes(project_id: project.id)
      end
    end
  end
end
