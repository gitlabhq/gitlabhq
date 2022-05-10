# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Resolvers::SnippetsResolver do
  include GraphqlHelpers

  describe '#resolve' do
    let_it_be(:current_user) { create(:user) }
    let_it_be(:other_user) { create(:user) }
    let_it_be(:project) { create(:project) }

    let_it_be(:personal_snippet) { create(:personal_snippet, :private, author: current_user) }
    let_it_be(:other_personal_snippet) { create(:personal_snippet, :internal, author: other_user) }
    let_it_be(:project_snippet) { create(:project_snippet, :internal, author: current_user, project: project) }
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
      it 'returns expected snippets' do
        expect(resolve_snippets).to contain_exactly(personal_snippet, other_personal_snippet, project_snippet, other_project_snippet)
      end
    end

    context 'when using filters' do
      context 'by author id' do
        it 'returns the snippets' do
          snippets = resolve_snippets(args: { author_id: global_id_of(current_user) })

          expect(snippets).to contain_exactly(personal_snippet, project_snippet)
        end
      end

      it 'returns the snippets by type' do
        aggregate_failures do
          expect(resolve_snippets(args: { type: 'personal' })).to contain_exactly(personal_snippet, other_personal_snippet)
          expect(resolve_snippets(args: { type: 'project' })).to contain_exactly(project_snippet, other_project_snippet)
        end
      end

      context 'by project id' do
        it 'returns the snippets' do
          snippets = resolve_snippets(args: { project_id: project.to_global_id })

          expect(snippets).to contain_exactly(project_snippet, other_project_snippet)
        end
      end

      it 'returns the snippets by visibility' do
        aggregate_failures do
          expect(resolve_snippets(args: { visibility: 'are_private' })).to contain_exactly(personal_snippet)
          expect(resolve_snippets(args: { visibility: 'are_internal' })).to contain_exactly(project_snippet, other_personal_snippet)
          expect(resolve_snippets(args: { visibility: 'are_public' })).to contain_exactly(other_project_snippet)
        end
      end

      it 'returns snippets to explore' do
        snippets = resolve_snippets(args: { explore: true })

        expect(snippets).to contain_exactly(other_personal_snippet)
      end

      it 'returns the snippets by single gid' do
        snippets = resolve_snippets(args: { ids: [global_id_of(personal_snippet)] })

        expect(snippets).to contain_exactly(personal_snippet)
      end

      it 'returns the snippets by array of gid' do
        snippets = [personal_snippet, project_snippet]
        args = { ids: snippets.map { |s| global_id_of(s) } }

        found = resolve_snippets(args: args)

        expect(found).to match_array(snippets)
      end

      it 'generates an error if both project and author are provided' do
        expect_graphql_error_to_be_created(Gitlab::Graphql::Errors::ArgumentError) do
          args = {
            author_id: current_user.to_global_id,
            project_id: project.to_global_id
          }

          resolve_snippets(args: args)
        end
      end
    end
  end

  def resolve_snippets(args: {})
    resolve(described_class, obj: nil, args: args, ctx: { current_user: current_user })
  end
end
