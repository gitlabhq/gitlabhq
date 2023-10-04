# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Resolvers::UserNotesCountResolver do
  include GraphqlHelpers

  describe '#resolve' do
    let_it_be(:user) { create(:user) }
    let_it_be(:project) { create(:project, :repository, :public) }
    let_it_be(:private_project) { create(:project, :repository, :private) }

    specify do
      expect(described_class).to have_nullable_graphql_type(GraphQL::Types::Int)
    end

    context 'when counting notes from an issue' do
      let_it_be(:issue) { create(:issue, project: project) }
      let_it_be(:private_issue) { create(:issue, project: private_project) }
      let_it_be(:public_notes) { create_list(:note, 2, noteable: issue, project: project) }
      let_it_be(:system_note) { create(:note, system: true, noteable: issue, project: project) }
      let_it_be(:private_notes) { create_list(:note, 3, noteable: private_issue, project: private_project) }

      context 'when counting notes from a public issue' do
        subject { batch_sync { resolve_user_notes_count(issue) } }

        it 'returns the number of non-system notes for the issue' do
          expect(subject).to eq(2)
        end

        context 'when not logged in' do
          let(:user) { nil }

          it 'returns the number of non-system notes for the issue' do
            expect(subject).to eq(2)
          end
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

      context 'when a user does not have permission to view notes' do
        subject { batch_sync { resolve_user_notes_count(private_issue) } }

        it 'generates an error' do
          expect_graphql_error_to_be_created(Gitlab::Graphql::Errors::ResourceNotAvailable) do
            subject
          end
        end
      end
    end

    context 'when counting notes from a merge request' do
      let_it_be(:merge_request) { create(:merge_request, source_project: project) }
      let_it_be(:private_merge_request) { create(:merge_request, source_project: private_project) }
      let_it_be(:public_notes) { create_list(:note, 2, noteable: merge_request, project: project) }
      let_it_be(:system_note) { create(:note, system: true, noteable: merge_request, project: project) }
      let_it_be(:private_notes) { create_list(:note, 3, noteable: private_merge_request, project: private_project) }

      context 'when counting notes from a public merge request' do
        subject { batch_sync { resolve_user_notes_count(merge_request) } }

        it 'returns the number of non-system notes for the merge request' do
          expect(subject).to eq(2)
        end

        context 'when not logged in' do
          let(:user) { nil }

          it 'returns the number of non-system notes for the merge request' do
            expect(subject).to eq(2)
          end
        end
      end

      context 'when a user has permission to view notes' do
        before do
          private_project.add_developer(user)
        end

        subject { batch_sync { resolve_user_notes_count(private_merge_request) } }

        it 'returns the number of notes for the merge request' do
          expect(subject).to eq(3)
        end
      end

      context 'when a user does not have permission to view notes' do
        subject { batch_sync { resolve_user_notes_count(private_merge_request) } }

        it 'generates an error' do
          expect_graphql_error_to_be_created(Gitlab::Graphql::Errors::ResourceNotAvailable) do
            subject
          end
        end
      end
    end
  end

  def resolve_user_notes_count(obj)
    resolve(described_class, obj: obj, ctx: { current_user: user })
  end
end
