# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Resolvers::UserDiscussionsCountResolver do
  include GraphqlHelpers

  describe '#resolve' do
    let_it_be(:user) { create(:user) }
    let_it_be(:project) { create(:project, :public) }
    let_it_be(:private_project) { create(:project, :private) }
    let_it_be(:issue) { create(:issue, project: project) }
    let_it_be(:private_issue) { create(:issue, project: private_project) }
    let_it_be(:public_discussions) { create_list(:discussion_note_on_issue, 2, noteable: issue, project: project) }
    let_it_be(:system_discussion) { create(:discussion_note_on_issue, system: true, noteable: issue, project: project) }
    let_it_be(:private_discussion) { create_list(:discussion_note_on_issue, 3, noteable: private_issue, project: private_project) }
    let_it_be(:work_item) { create(:work_item, project: project) }
    let_it_be(:private_work_item) { create(:work_item, project: private_project) }
    let_it_be(:public_discussions_on_work_item) { create_list(:discussion_note_on_work_item, 2, noteable: work_item, project: project) }
    let_it_be(:system_discussion_on_work_item) { create(:discussion_note_on_work_item, system: true, noteable: work_item, project: project) }

    specify do
      expect(described_class).to have_nullable_graphql_type(GraphQL::Types::Int)
    end

    context 'when counting discussions from a work item' do
      subject { batch_sync { resolve_user_discussions_count(work_item) } }

      it 'returns the number of discussions for the work item' do
        expect(subject).to eq(2)
      end
    end

    context 'when counting discussions from a public issue' do
      subject { batch_sync { resolve_user_discussions_count(issue) } }

      it 'returns the number of discussions for the issue' do
        expect(subject).to eq(2)
      end
    end

    context 'when a user has permission to view discussions' do
      before do
        private_project.add_developer(user)
      end

      subject { batch_sync { resolve_user_discussions_count(private_issue) } }

      it 'returns the number of non-system discussions for the issue' do
        expect(subject).to eq(3)
      end
    end
  end

  def resolve_user_discussions_count(obj)
    resolve(described_class, obj: obj, ctx: { current_user: user })
  end
end
