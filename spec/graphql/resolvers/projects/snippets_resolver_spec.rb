# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Resolvers::Projects::SnippetsResolver do
  include GraphqlHelpers

  describe '#resolve' do
    let_it_be(:user) { create(:user) }
    let_it_be(:other_user) { create(:user) }
    let_it_be(:project) { create(:project) }

    let_it_be(:personal_snippet) { create(:personal_snippet, :private, author: user) }
    let_it_be(:project_snippet) { create(:project_snippet, :internal, author: user, project: project) }
    let_it_be(:other_project_snippet) { create(:project_snippet, :public, author: other_user, project: project) }

    let(:current_user) { user }

    before_all do
      project.add_developer(user)
    end

    it 'calls SnippetsFinder' do
      expect_next_instance_of(SnippetsFinder) do |finder|
        expect(finder).to receive(:execute)
      end

      resolve_snippets
    end

    context 'when using no filter' do
      it 'returns expected snippets' do
        expect(resolve_snippets).to contain_exactly(project_snippet, other_project_snippet)
      end
    end

    context 'when using filters' do
      it 'returns the snippets by visibility' do
        aggregate_failures do
          expect(resolve_snippets(args: { visibility: 'are_private' })).to be_empty
          expect(resolve_snippets(args: { visibility: 'are_internal' })).to contain_exactly(project_snippet)
          expect(resolve_snippets(args: { visibility: 'are_public' })).to contain_exactly(other_project_snippet)
        end
      end

      it 'returns the snippets by gid' do
        snippets = resolve_snippets(args: { ids: [global_id_of(project_snippet)] })

        expect(snippets).to contain_exactly(project_snippet)
      end

      it 'returns the snippets by array of gid' do
        args = {
          ids: [global_id_of(project_snippet), global_id_of(other_project_snippet)]
        }

        snippets = resolve_snippets(args: args)

        expect(snippets).to contain_exactly(project_snippet, other_project_snippet)
      end
    end

    context 'when no project is provided' do
      it 'returns no snippets' do
        expect(resolve_snippets(obj: nil)).to be_empty
      end
    end

    context 'when provided user is not current user' do
      let(:current_user) { other_user }

      it 'returns no snippets' do
        expect(resolve_snippets(args: { ids: [global_id_of(project_snippet)] })).to be_empty
      end
    end

    context 'when project snippets are disabled' do
      it 'generates an error' do
        disabled_snippet_project = create(:project, :snippets_disabled)
        disabled_snippet_project.add_developer(current_user)

        expect(SnippetsFinder).not_to receive(:new)
        expect_graphql_error_to_be_created(Gitlab::Graphql::Errors::ResourceNotAvailable) do
          resolve_snippets(obj: disabled_snippet_project)
        end
      end
    end
  end

  def resolve_snippets(args: {}, context: { current_user: current_user }, obj: project)
    resolve(described_class, obj: obj, args: args, ctx: context)
  end
end
