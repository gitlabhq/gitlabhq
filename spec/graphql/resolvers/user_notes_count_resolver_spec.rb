# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Resolvers::UserNotesCountResolver do
  include GraphqlHelpers

  describe '#resolve' do
    let_it_be(:user) { create(:user) }
    let_it_be(:project) { create(:project, :public) }
    let_it_be(:private_project) { create(:project, :private) }
    let_it_be(:issue) { create(:issue, project: project) }
    let_it_be(:private_issue) { create(:issue, project: private_project) }
    let_it_be(:public_notes) { create_list(:note, 2, noteable: issue, project: project) }
    let_it_be(:system_note) { create(:note, system: true, noteable: issue, project: project) }
    let_it_be(:private_notes) { create_list(:note, 3, noteable: private_issue, project: private_project) }

    specify do
      expect(described_class).to have_nullable_graphql_type(GraphQL::INT_TYPE)
    end

    context 'when counting notes from a public issue' do
      subject { batch_sync { resolve_user_notes_count(issue) } }

      it 'returns the number of non-system notes for the issue' do
        expect(subject).to eq(2)
      end
    end

    context 'when a user has permission to view notes' do
      before do
        private_project.add_developer(user)
      end

      subject { batch_sync { resolve_user_notes_count(private_issue) } }

      it 'returns the number of notes for the issue' do
        expect(subject).to eq(3)
      end
    end

    context 'when a user does not have permission to view discussions' do
      subject { batch_sync { resolve_user_notes_count(private_issue) } }

      it 'returns no notes' do
        expect { subject }.to raise_error(Gitlab::Graphql::Errors::ResourceNotAvailable)
      end
    end
  end

  def resolve_user_notes_count(obj)
    resolve(described_class, obj: obj, ctx: { current_user: user })
  end
end
