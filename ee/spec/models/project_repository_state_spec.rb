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

  describe '#repository_checksum_outdated?' do
    it 'returns true when repository_verification_checksum is nil' do
      repository_state.repository_verification_checksum = nil

      expect(repository_state.repository_checksum_outdated?).to eq true
    end

    it 'returns false when repository_verification_checksum is not nil' do
      repository_state.repository_verification_checksum = '123'

      expect(repository_state.repository_checksum_outdated?).to eq false
    end
  end

  describe '#wiki_checksum_outdated?' do
    context 'wiki enabled' do
      it 'returns true when wiki_verification_checksum is nil' do
        repository_state.wiki_verification_checksum = nil

        expect(repository_state.wiki_checksum_outdated?).to eq true
      end

      it 'returns false when wiki_verification_checksum is not nil' do
        repository_state.wiki_verification_checksum = '123'

        expect(repository_state.wiki_checksum_outdated?).to eq false
      end
    end

    context 'wiki disabled' do
      it 'returns false' do
        project.update!(wiki_enabled: false)

        expect(repository_state.wiki_checksum_outdated?).to eq false
      end
    end
  end
end
