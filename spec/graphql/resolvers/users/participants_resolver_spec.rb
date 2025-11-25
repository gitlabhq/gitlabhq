# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Resolvers::Users::ParticipantsResolver do
  include GraphqlHelpers

  describe '#resolve' do
    let_it_be(:user) { create(:user) }
    let_it_be(:guest) { create(:user) }
    let_it_be(:project) do
      create(:project, :public).tap do |r|
        r.add_developer(user)
        r.add_guest(guest)
      end
    end

    let_it_be(:private_project) { create(:project, :private, developers: user) }

    let_it_be(:issue) { create(:issue, project: project) }
    let_it_be(:private_issue) { create(:issue, project: private_project) }

    let_it_be(:public_note_author) { create(:user) }
    let_it_be(:public_reply_author) { create(:user) }
    let_it_be(:internal_note_author) { create(:user) }
    let_it_be(:internal_reply_author) { create(:user) }
    let_it_be(:system_note_author) { create(:user) }
    let_it_be(:internal_system_note_author) { create(:user) }

    let_it_be(:public_note) { create(:note, project: project, noteable: issue, author: public_note_author) }
    let_it_be(:internal_note) { create(:note, :confidential, project: project, noteable: issue, author: internal_note_author) }

    let_it_be(:public_reply) do
      create(:note, noteable: issue, in_reply_to: public_note, project: project, author: public_reply_author)
    end

    let_it_be(:internal_reply) do
      create(:note, :confidential, noteable: issue, in_reply_to: internal_note, project: project, author: internal_reply_author)
    end

    let_it_be(:issue_emoji_author) { create(:award_emoji, name: AwardEmoji::THUMBS_UP, awardable: issue).user }
    let_it_be(:public_note_emoji_author) { create(:award_emoji, name: AwardEmoji::THUMBS_UP, awardable: public_note).user }
    let_it_be(:internal_note_emoji_author) { create(:award_emoji, name: AwardEmoji::THUMBS_UP, awardable: internal_note).user }
    let_it_be(:public_reply_emoji_author) { create(:award_emoji, name: AwardEmoji::THUMBS_UP, awardable: public_reply).user }
    let_it_be(:internal_reply_emoji_author) { create(:award_emoji, name: AwardEmoji::THUMBS_UP, awardable: internal_reply).user }

    let(:expected_participants) do
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
        internal_reply_emoji_author,
        system_note_author,
        internal_system_note_author
      ]
    end

    subject(:resolved_items) do
      resolve(described_class, args: {}, ctx: { current_user: current_user }, obj: issue)&.items
    end

    before_all do
      create(:system_note, project: project, noteable: issue, author: system_note_author)
      create(
        :system_note,
        note: "mentioned in issue #{private_issue.to_reference(full: true)}",
        project: project, noteable: issue, author: internal_system_note_author
      )
      create(:system_note_metadata, note: public_note)
    end

    context 'when current user is not set' do
      let(:current_user) { nil }

      it 'returns all participants' do
        is_expected.to match_array(expected_participants)
      end
    end

    context 'when current user does not have enough permissions' do
      let(:current_user) { guest }

      it 'returns all participants' do
        is_expected.to match_array(expected_participants)
      end
    end

    context 'when current user has access to internal notes' do
      let(:current_user) { user }

      it 'returns all participants' do
        is_expected.to match_array(expected_participants)
      end

      context 'N+1 queries' do
        let(:query) do
          -> { resolve(described_class, args: {}, ctx: { current_user: current_user }, obj: issue)&.items }
        end

        before do
          # warm-up
          query.call
        end

        it 'does not execute N+1 queries when adding participants', :request_store do
          control_count = ActiveRecord::QueryRecorder.new { query.call }

          create(:award_emoji, :upvote, awardable: issue)
          internal_note = create(:note, :confidential, project: project, noteable: issue, author: create(:user))
          create(:award_emoji, name: AwardEmoji::THUMBS_UP, awardable: internal_note)
          public_note = create(:note, project: project, noteable: issue, author: create(:user))
          create(:award_emoji, name: AwardEmoji::THUMBS_UP, awardable: public_note)

          expect { query.call }.not_to exceed_query_limit(control_count)
        end
      end
    end
  end
end
