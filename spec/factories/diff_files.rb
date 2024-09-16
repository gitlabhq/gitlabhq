# frozen_string_literal: true

require_relative '../support/helpers/repo_helpers'

FactoryBot.define do
  factory :diff_file, class: 'Gitlab::Diff::File' do
    repository { create(:project, :repository).repository }
    diff { repository.commit(RepoHelpers.sample_commit.id).raw_diffs.first }
    diff_refs { repository.commit(RepoHelpers.sample_commit.id).diff_refs }

    initialize_with do
      new(
        attributes[:diff],
        diff_refs: attributes[:diff_refs],
        repository: attributes[:repository]
      )
    end
  end
end
