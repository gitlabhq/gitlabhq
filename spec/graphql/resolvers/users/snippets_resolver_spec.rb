# frozen_string_literal: true

require 'spec_helper'

describe Resolvers::Users::SnippetsResolver do
  include GraphqlHelpers

  describe '#resolve' do
    let_it_be(:current_user) { create(:user) }
    let_it_be(:other_user) { create(:user) }
    let_it_be(:project) { create(:project) }

    let_it_be(:private_personal_snippet) { create(:personal_snippet, :private, author: current_user) }
    let_it_be(:public_personal_snippet) { create(:personal_snippet, :public, author: current_user) }
    let_it_be(:other_personal_snippet) { create(:personal_snippet, :internal, author: other_user) }
    let_it_be(:internal_project_snippet) { create(:project_snippet, :internal, author: current_user, project: project) }
    let_it_be(:other_project_snippet) { create(:project_snippet, :public, author: other_user, project: project) }

    before do
      project.add_developer(current_user)
    end

    it 'calls SnippetsFinder' do
      expect_next_instance_of(SnippetsFinder) do |finder|
        expect(finder).to receive(:execute)
      end

      resolve_snippets
    end

    context 'when using no filter' do
      it 'returns expected authored snippets' do
        expect(resolve_snippets).to contain_exactly(private_personal_snippet, public_personal_snippet, internal_project_snippet)
      end
    end

    context 'when using filters' do
      it 'returns the snippets by visibility' do
        aggregate_failures do
          expect(resolve_snippets(args: { visibility: 'are_private' })).to contain_exactly(private_personal_snippet)
          expect(resolve_snippets(args: { visibility: 'are_internal' })).to contain_exactly(internal_project_snippet)
          expect(resolve_snippets(args: { visibility: 'are_public' })).to contain_exactly(public_personal_snippet)
        end
      end

      it 'returns the snippets by type' do
        aggregate_failures do
          expect(resolve_snippets(args: { type: 'personal' })).to contain_exactly(private_personal_snippet, public_personal_snippet)
          expect(resolve_snippets(args: { type: 'project' })).to contain_exactly(internal_project_snippet)
        end
      end

      it 'returns the snippets by single gid' do
        snippets = resolve_snippets(args: { ids: private_personal_snippet.to_global_id })

        expect(snippets).to contain_exactly(private_personal_snippet)
      end

      it 'returns the snippets by array of gid' do
        args = {
          ids: [private_personal_snippet.to_global_id, public_personal_snippet.to_global_id]
        }

        snippets = resolve_snippets(args: args)

        expect(snippets).to contain_exactly(private_personal_snippet, public_personal_snippet)
      end

      it 'returns an error if the gid is invalid' do
        args = {
          ids: [private_personal_snippet.to_global_id, 'foo']
        }

        expect do
          resolve_snippets(args: args)
        end.to raise_error(Gitlab::Graphql::Errors::ArgumentError)
      end
    end
  end

  def resolve_snippets(args: {})
    resolve(described_class, args: args, ctx: { current_user: current_user }, obj: current_user)
  end
end
