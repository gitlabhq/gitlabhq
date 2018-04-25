require 'spec_helper'

RSpec.describe Geo::RepositoryRenamedEvent, type: :model do
  describe 'relationships' do
    it { is_expected.to belong_to(:project) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:project) }
    it { is_expected.to validate_presence_of(:repository_storage_name) }
    it { is_expected.to validate_presence_of(:old_path_with_namespace) }
    it { is_expected.to validate_presence_of(:new_path_with_namespace) }
    it { is_expected.to validate_presence_of(:old_wiki_path_with_namespace) }
    it { is_expected.to validate_presence_of(:new_wiki_path_with_namespace) }
    it { is_expected.to validate_presence_of(:old_path) }
    it { is_expected.to validate_presence_of(:new_path) }
  end
end
