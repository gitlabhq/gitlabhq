# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::BackgroundMigration::ResetChecksumFromProjectRepositoryStates, :migration, schema: 20180914195058 do
  describe '#perform' do
    it 'processes all repository states in batch' do
      repository_state_1 = create(:repository_state, :repository_verified, :wiki_verified)
      repository_state_2 = create(:repository_state, :repository_failed, :wiki_failed)
      repository_state_3 = create(:repository_state, :repository_verified, :wiki_verified)

      subject.perform(repository_state_1.project_id, repository_state_2.project_id)

      expect(repository_state_1.reload).to have_attributes(
        repository_verification_checksum: be_nil,
        wiki_verification_checksum: be_nil,
        last_repository_verification_failure: be_nil,
        last_wiki_verification_failure: be_nil,
        repository_retry_at: be_nil,
        wiki_retry_at: be_nil,
        repository_retry_count: be_nil,
        wiki_retry_count: be_nil
      )

      expect(repository_state_2.reload).to have_attributes(
        repository_verification_checksum: be_nil,
        wiki_verification_checksum: be_nil,
        last_repository_verification_failure: be_nil,
        last_wiki_verification_failure: be_nil,
        repository_retry_at: be_nil,
        wiki_retry_at: be_nil,
        repository_retry_count: be_nil,
        wiki_retry_count: be_nil
      )

      expect(repository_state_3.reload).to have_attributes(
        repository_verification_checksum: be_present,
        wiki_verification_checksum: be_present
      )
    end
  end
end
