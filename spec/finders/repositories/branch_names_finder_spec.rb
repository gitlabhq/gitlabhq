# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Repositories::BranchNamesFinder, feature_category: :source_code_management do
  let(:project) { create(:project, :repository) }

  describe '#execute' do
    it 'returns a limited number of offset filtered branch names' do
      starting_names = create_branch_names_finder(0, 3, 'snippet/*').execute
      offset_names = create_branch_names_finder(3, 2, 'snippet/*').execute

      expect(starting_names.count).to eq(3)
      expect(offset_names.count).to eq(2)

      expect(offset_names).not_to include(*starting_names)

      all_names = create_branch_names_finder(0, 100, 'snippet/*').execute
      expect(all_names).to contain_exactly(*starting_names, *offset_names)
    end

    it 'returns all filtered branch names sorted alphabetically with no matching default branch' do
      expect(create_branch_names_finder(0, 100, 'conflict-*').execute).to eq(%w[
        conflict-binary-file
        conflict-contains-conflict-markers
        conflict-missing-side
        conflict-non-utf8
        conflict-resolvable
        conflict-start
        conflict-too-large
      ])
    end

    it 'returns all filtered branch names sorted alphabetically with default branch at the top' do
      expect(create_branch_names_finder(0, 100, 'm*').execute).to eq(%w[
        master
        markdown
        merge-commit-analyze-after
        merge-commit-analyze-before
        merge-commit-analyze-side-branch
        merge-test
        merged-target
      ])
    end

    private

    def create_branch_names_finder(offset, limit, search_pattern)
      described_class.new(project.repository, search: search_pattern, offset: offset, limit: limit)
    end
  end
end
