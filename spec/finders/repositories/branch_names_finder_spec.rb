# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Repositories::BranchNamesFinder do
  let(:project) { create(:project, :repository) }

  describe '#execute' do
    it 'returns all filtered branch names' do
      expect(create_branch_names_finder(0, 100).execute).to contain_exactly(
        'snippet/edit-file',
        'snippet/multiple-files',
        'snippet/no-files',
        'snippet/rename-and-edit-file',
        'snippet/single-file'
      )
    end

    it 'returns a limited number of offset filtered branch names' do
      starting_names = create_branch_names_finder(0, 3).execute
      offset_names = create_branch_names_finder(3, 2).execute

      expect(starting_names.count).to eq(3)
      expect(offset_names.count).to eq(2)

      expect(offset_names).not_to include(*starting_names)

      all_names = create_branch_names_finder(0, 100).execute
      expect(all_names).to contain_exactly(*starting_names, *offset_names)
    end

    private

    def create_branch_names_finder(offset, limit)
      described_class.new(project.repository, search: 'snippet/*', offset: offset, limit: limit)
    end
  end
end
