# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Resolvers::LastCommitResolver do
  include GraphqlHelpers
  include RepoHelpers

  let(:project) { create(:project, :repository) }
  let(:repository) { project.repository }
  let(:tree) { repository.tree(ref, path) }

  let(:commit) { resolve(described_class, obj: tree) }

  describe '#resolve' do
    context 'last commit is a merge commit' do
      let(:ref) { 'master' }
      let(:path) { '/' }

      it 'resolves to the merge commit' do
        expect(commit).to eq(repository.commits(ref, limit: 1).last)
      end
    end

    context 'last commit for a different branch and path' do
      let(:ref) { 'fix' }
      let(:path) { 'files' }

      it 'resolves commit' do
        expect(commit).to eq(repository.commits(ref, path: path, limit: 1).last)
      end
    end

    context 'last commit for a wildcard pathspec' do
      let(:ref) { 'fix' }
      let(:path) { 'files/*' }

      it 'returns nil' do
        expect(commit).to be_nil
      end
    end

    context 'last commit with pathspec characters' do
      let(:ref) { 'fix' }
      let(:path) { ':wq' }

      before do
        create_file_in_repo(project, ref, ref, path, 'Test file')
      end

      it 'resolves commit' do
        expect(commit).to eq(repository.commits(ref, path: path, limit: 1).last)
      end
    end

    context 'last commit does not exist' do
      let(:ref) { 'master' }
      let(:path) { 'does-not-exist' }

      it 'returns nil' do
        expect(commit).to be_nil
      end
    end

    context 'when the ref is ambiguous' do
      let(:ambiguous_ref) { 'v1.0.0' }

      before do
        project.repository.create_branch(ambiguous_ref)
      end

      context 'when tree is for a tag' do
        let(:tree) { repository.tree(ambiguous_ref, ref_type: 'tags') }

        it 'resolves commit' do
          expect(commit.id).to eq(repository.find_tag(ambiguous_ref).dereferenced_target.id)
        end
      end

      context 'when tree is for a branch' do
        let(:tree) { repository.tree(ambiguous_ref, ref_type: 'heads') }

        it 'resolves commit' do
          expect(commit.id).to eq(repository.find_branch(ambiguous_ref).target)
        end
      end
    end
  end
end
