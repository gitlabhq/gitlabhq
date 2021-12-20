# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Resolvers::Users::ParticipantsResolver do
  include GraphqlHelpers

  describe '#resolve' do
    let_it_be(:user) { create(:user) }
    let_it_be(:guest) { create(:user) }
    let_it_be(:project) { create(:project, :public) }
    let_it_be(:issue) { create(:issue, project: project) }
    let_it_be(:note) do
      create(
        :note,
        :system,
        :confidential,
        project: project,
        noteable: issue,
        author: create(:user)
      )
    end

    let_it_be(:note_metadata) { create(:system_note_metadata, note: note) }

    subject(:resolved_items) { resolve(described_class, args: {}, ctx: { current_user: current_user }, obj: issue)&.items }

    before do
      project.add_guest(guest)
      project.add_developer(user)
    end

    context 'when current user is not set' do
      let(:current_user) { nil }

      it 'returns only publicly visible participants for this user' do
        is_expected.to match_array([issue.author])
      end
    end

    context 'when current user does not have enough permissions' do
      let(:current_user) { guest }

      it 'returns only publicly visible participants for this user' do
        is_expected.to match_array([issue.author])
      end
    end

    context 'when current user has access to confidential notes' do
      let(:current_user) { user }

      it 'returns all participants for this user' do
        is_expected.to match_array([issue.author, note.author])
      end

      context 'N+1 queries' do
        let(:query) { -> { resolve(described_class, args: {}, ctx: { current_user: current_user }, obj: issue)&.items } }

        before do
          # warm-up
          query.call
        end

        it 'does not execute N+1 for project relation' do
          control_count = ActiveRecord::QueryRecorder.new { query.call }

          create(:note, :confidential, project: project, noteable: issue, author: create(:user))

          expect { query.call }.not_to exceed_query_limit(control_count)
        end

        it 'does not execute N+1 for system note metadata relation' do
          control_count = ActiveRecord::QueryRecorder.new { query.call }

          new_note = create(:note, :system, project: project, noteable: issue, author: create(:user))
          create(:system_note_metadata, note: new_note)

          expect { query.call }.not_to exceed_query_limit(control_count)
        end
      end
    end
  end
end
