require 'spec_helper'

describe Geo::FileRegistryFinder, :geo do
  include ::EE::GeoHelpers

  let(:secondary) { create(:geo_node) }

  subject { described_class.new(current_node: secondary) }

  before do
    stub_current_geo_node(secondary)
  end

  describe '#find_failed_file_registries' do
    it 'returs uploads that sync has failed' do
      failed_lfs_registry = create(:geo_file_registry, :lfs, :with_file, success: false)
      failed_file_upload = create(:geo_file_registry, :with_file, success: false)
      failed_issuable_upload = create(:geo_file_registry, :with_file, success: false)
      create(:geo_file_registry, :lfs, :with_file, success: true)
      create(:geo_file_registry, :with_file, success: true)

      uploads = subject.find_failed_file_registries(batch_size: 10)

      expect(uploads).to match_array([failed_lfs_registry, failed_file_upload, failed_issuable_upload])
    end
  end
end
