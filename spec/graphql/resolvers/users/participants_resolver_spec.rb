# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Resolvers::Users::ParticipantsResolver do
  include GraphqlHelpers

  describe '#resolve' do
    let_it_be(:user) { create(:user) }
    let_it_be(:guest) { create(:user) }
    let_it_be(:project) { create(:project, :public) }
    let_it_be(:issue) { create(:issue, project: project) }

    let_it_be(:public_note_author) { create(:user) }
    let_it_be(:public_reply_author) { create(:user) }
    let_it_be(:internal_note_author) { create(:user) }
    let_it_be(:internal_reply_author) { create(:user) }

    let_it_be(:public_note) { create(:note, project: project, noteable: issue, author: public_note_author) }
    let_it_be(:internal_note) { create(:note, :confidential, project: project, noteable: issue, author: internal_note_author) }

    let_it_be(:public_reply) { create(:note, noteable: issue, in_reply_to: public_note, project: project, author: public_reply_author) }
    let_it_be(:internal_reply) { create(:note, :confidential, noteable: issue, in_reply_to: internal_note, project: project, author: internal_reply_author) }

    let_it_be(:note_metadata2) { create(:system_note_metadata, note: public_note) }

    let_it_be(:issue_emoji) { create(:award_emoji, name: 'thumbsup', awardable: issue) }
    let_it_be(:note_emoji1) { create(:award_emoji, name: 'thumbsup', awardable: public_note) }
    let_it_be(:note_emoji2) { create(:award_emoji, name: 'thumbsup', awardable: internal_note) }
    let_it_be(:note_emoji3) { create(:award_emoji, name: 'thumbsup', awardable: public_reply) }
    let_it_be(:note_emoji4) { create(:award_emoji, name: 'thumbsup', awardable: internal_reply) }

    let_it_be(:issue_emoji_author) { issue_emoji.user }
    let_it_be(:public_note_emoji_author) { note_emoji1.user }
    let_it_be(:internal_note_emoji_author) { note_emoji2.user }
    let_it_be(:public_reply_emoji_author) { note_emoji3.user }
    let_it_be(:internal_reply_emoji_author) { note_emoji4.user }

    subject(:resolved_items) { resolve(described_class, args: {}, ctx: { current_user: current_user }, obj: issue)&.items }

    before do
      project.add_guest(guest)
      project.add_developer(user)
    end

    context 'when current user is not set' do
      let(:current_user) { nil }

      it 'returns only publicly visible participants for this user' do
        is_expected.to match_array(
          [
            issue.author,
            issue_emoji_author,
            public_note_author,
            public_note_emoji_author,
            public_reply_author,
            public_reply_emoji_author
          ]
        )
      end
    end

    context 'when current user does not have enough permissions' do
      let(:current_user) { guest }

      it 'returns only publicly visible participants for this user' do
        is_expected.to match_array(
          [
            issue.author,
            issue_emoji_author,
            public_note_author,
            public_note_emoji_author,
            public_reply_author,
            public_reply_emoji_author
          ]
        )
      end
    end

    context 'when current user has access to internal notes' do
      let(:current_user) { user }

      it 'returns all participants for this user' do
        is_expected.to match_array(
          [
            issue.author,
            issue_emoji_author,
            public_note_author,
            public_note_emoji_author,
            public_reply_author,
            internal_note_author,
            internal_note_emoji_author,
            internal_reply_author,
            public_reply_emoji_author,
            internal_reply_emoji_author
          ]
        )
      end

      context 'N+1 queries' do
        let(:query) { -> { resolve(described_class, args: {}, ctx: { current_user: current_user }, obj: issue)&.items } }

        before do
          # warm-up
          query.call
        end

        it 'does not execute N+1 for project relation' do
          control_count = ActiveRecord::QueryRecorder.new { query.call }

          create(:award_emoji, :upvote, awardable: issue)
          internal_note = create(:note, :confidential, project: project, noteable: issue, author: create(:user))
          create(:award_emoji, name: 'thumbsup', awardable: internal_note)
          public_note = create(:note, project: project, noteable: issue, author: create(:user))
          create(:award_emoji, name: 'thumbsup', awardable: public_note)

          # 1 extra query per source (3 emojis + 2 notes) to fetch participables collection
          # 2 extra queries to load work item widgets collection
          expect { query.call }.not_to exceed_query_limit(control_count).with_threshold(7)
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
