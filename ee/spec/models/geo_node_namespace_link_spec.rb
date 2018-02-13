require 'spec_helper'

describe GeoNodeNamespaceLink, models: true do
  describe 'relationships' do
    it { is_expected.to belong_to(:geo_node) }
    it { is_expected.to belong_to(:namespace) }
  end

  describe 'validations' do
    let!(:geo_node_namespace_link) { create(:geo_node_namespace_link) }

    it { is_expected.to validate_presence_of(:namespace_id) }
    it { is_expected.to validate_uniqueness_of(:namespace_id).scoped_to(:geo_node_id) }
  end
end
