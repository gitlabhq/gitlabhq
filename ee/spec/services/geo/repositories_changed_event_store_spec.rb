# frozen_string_literal: true

require 'spec_helper'

describe Geo::RepositoriesChangedEventStore do
  include EE::GeoHelpers

  let(:geo_node) { create(:geo_node) }

  subject { described_class.new(geo_node) }

  describe '#create!' do
    it_behaves_like 'a Geo event store', Geo::RepositoriesChangedEvent
  end
end
