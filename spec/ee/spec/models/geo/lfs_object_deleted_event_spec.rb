require 'spec_helper'

RSpec.describe Geo::LfsObjectDeletedEvent, type: :model do
  describe 'relationships' do
    it { is_expected.to belong_to(:lfs_object) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:lfs_object) }
    it { is_expected.to validate_presence_of(:oid) }
    it { is_expected.to validate_presence_of(:file_path) }
  end
end
