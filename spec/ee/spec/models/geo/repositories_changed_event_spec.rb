require 'spec_helper'

describe Geo::RepositoriesChangedEvent, type: :model do
  describe 'relationships' do
    it { is_expected.to belong_to(:geo_node) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:geo_node) }
  end
end
