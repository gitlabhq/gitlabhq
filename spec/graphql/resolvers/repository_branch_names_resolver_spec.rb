# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Resolvers::RepositoryBranchNamesResolver do
  include GraphqlHelpers

  let(:project) { create(:project, :repository) }

  describe '#resolve' do
    context 'with empty search pattern' do
      let(:pattern) { '' }

      it 'returns nil' do
        expect(resolve_branch_names(pattern, 0, 100)).to eq(nil)
      end
    end

    context 'with a valid search pattern' do
      let(:pattern) { 'snippet/*' }

      it 'returns matching branches' do
        expect(resolve_branch_names(pattern, 0, 100)).to contain_exactly(
          'snippet/edit-file',
          'snippet/multiple-files',
          'snippet/no-files',
          'snippet/rename-and-edit-file',
          'snippet/single-file'
        )
      end

      it 'properly offsets and limits branch name results' do
        starting_names = resolve_branch_names(pattern, 0, 3)
        offset_names = resolve_branch_names(pattern, 3, 2)

        expect(starting_names.count).to eq(3)
        expect(offset_names.count).to eq(2)

        expect(offset_names).not_to include(*starting_names)

        all_names = resolve_branch_names(pattern, 0, 100)
        expect(all_names).to contain_exactly(*starting_names, *offset_names)
      end
    end
  end

  private

  def resolve_branch_names(pattern, offset, limit)
    resolve(
      described_class,
      obj: project.repository,
      args: { search_pattern: pattern, offset: offset, limit: limit },
      ctx: { current_user: project.creator }
    )
  end
end
