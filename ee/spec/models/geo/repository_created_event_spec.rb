require 'spec_helper'

describe Geo::RepositoryCreatedEvent, type: :model do
  describe 'relationships' do
    it { is_expected.to belong_to(:project) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:project) }
    it { is_expected.to validate_presence_of(:project_name) }
    it { is_expected.to validate_presence_of(:repo_path) }
    it { is_expected.to validate_presence_of(:repository_storage_name) }
  end
end
