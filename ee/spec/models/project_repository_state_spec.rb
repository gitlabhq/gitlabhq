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
    where(:repository_verification_checksum, :last_repository_verification_at, :expected) do
      now = Time.now
      past = now - 1.year
      future = now + 1.year

      nil   | nil    | true
      '123' | nil    | true
      '123' | past   | true
      '123' | now    | true
      '123' | future | false
    end

    with_them do
      before do
        repository_state.update!(repository_verification_checksum: repository_verification_checksum, last_repository_verification_at: last_repository_verification_at)
      end

      subject { repository_state.repository_checksum_outdated?(Time.now) }

      it { is_expected.to eq(expected) }
    end
  end

  describe '#wiki_checksum_outdated?' do
    where(:wiki_verification_checksum, :last_wiki_verification_at, :expected) do
      now = Time.now
      past = now - 1.year
      future = now + 1.year

      nil   | nil    | true
      '123' | nil    | true
      '123' | past   | true
      '123' | now    | true
      '123' | future | false
    end

    with_them do
      before do
        repository_state.update!(wiki_verification_checksum: wiki_verification_checksum, last_wiki_verification_at: last_wiki_verification_at)
      end

      subject { repository_state.wiki_checksum_outdated?(Time.now) }

      context 'wiki enabled' do
        it { is_expected.to eq(expected) }
      end

      context 'wiki disabled' do
        before do
          project.update!(wiki_enabled: false)
        end

        it { is_expected.to be_falsy }
      end
    end
  end
end
