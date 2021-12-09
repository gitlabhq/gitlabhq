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
        :confidential,
        project: project,
        noteable: issue,
        author: create(:user)
      )
    end

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
    end
  end
end
