require 'rails_helper'

describe ProjectRepositoryState do
  using RSpec::Parameterized::TableSyntax

  set(:project) { create(:project) }
  set(:repository_state) { create(:repository_state, project_id: project.id) }

  subject { repository_state }

  describe 'assocations' do
    it { is_expected.to belong_to(:project).inverse_of(:repository_state) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:project) }
    it { is_expected.to validate_uniqueness_of(:project) }
  end
end
