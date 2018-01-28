require 'spec_helper'

describe AutocompleteUsersFinder do
  describe '#execute' do
    let!(:user1) { create(:user, username: 'johndoe') }
    let!(:user2) { create(:user, :blocked, username: 'notsorandom') }
    let!(:external_user) { create(:user, :external) }
    let!(:omniauth_user) { create(:omniauth_user, provider: 'twitter', extern_uid: '123456') }
    let(:current_user) { create(:user) }
    let(:params) { {} }

    let(:project) { nil }
    let(:group) { nil }

    subject { described_class.new(params: params, current_user: current_user, project: project, group: group).execute.to_a }

    context 'when current_user not passed or nil' do
      let(:current_user) { nil }

      it { is_expected.to match_array([]) }
    end

    context 'when project passed' do
      let(:project) { create(:project) }

      it { is_expected.to match_array([project.owner]) }

      context 'when author_id passed' do
        let(:params) { { author_id: user2.id } }

        it { is_expected.to match_array([project.owner, user2]) }
      end
    end

    context 'when group passed and project not passed' do
      let(:group) { create(:group, :public) }

      before do
        group.add_users([user1], GroupMember::DEVELOPER)
      end

      it { is_expected.to match_array([user1]) }
    end

    context 'when passed a subgroup', :nested_groups do
      let(:grandparent) { create(:group, :public) }
      let(:parent) { create(:group, :public, parent: grandparent) }
      let(:child) { create(:group, :public, parent: parent) }
      let(:group) { parent }

      let!(:grandparent_user) { create(:group_member, :developer, group: grandparent).user }
      let!(:parent_user) { create(:group_member, :developer, group: parent).user }
      let!(:child_user) { create(:group_member, :developer, group: child).user }

      it 'includes users from parent groups as well' do
        expect(subject).to match_array([grandparent_user, parent_user])
      end
    end

    it { is_expected.to match_array([user1, external_user, omniauth_user, current_user]) }

    context 'when filtered by search' do
      let(:params) { { search: 'johndoe' } }

      it { is_expected.to match_array([user1]) }
    end

    context 'when filtered by skip_users' do
      let(:params) { { skip_users: [omniauth_user.id, current_user.id] } }

      it { is_expected.to match_array([user1, external_user]) }
    end

    context 'when todos exist' do
      let!(:pending_todo1) { create(:todo, user: current_user, author: user1, state: :pending) }
      let!(:pending_todo2) { create(:todo, user: external_user, author: omniauth_user, state: :pending) }
      let!(:done_todo1) { create(:todo, user: current_user, author: external_user, state: :done) }
      let!(:done_todo2) { create(:todo, user: user1, author: external_user, state: :done) }

      context 'when filtered by todo_filter without todo_state_filter' do
        let(:params) { { todo_filter: true } }

        it { is_expected.to match_array([]) }
      end

      context 'when filtered by todo_filter with pending todo_state_filter' do
        let(:params) { { todo_filter: true, todo_state_filter: 'pending' } }

        it { is_expected.to match_array([user1]) }
      end

      context 'when filtered by todo_filter with done todo_state_filter' do
        let(:params) { { todo_filter: true, todo_state_filter: 'done' } }

        it { is_expected.to match_array([external_user]) }
      end
    end

    context 'when filtered by current_user' do
      let(:current_user) { user2 }
      let(:params) { { current_user: true } }

      it { is_expected.to match_array([user2, user1, external_user, omniauth_user]) }
    end

    context 'when filtered by author_id' do
      let(:params) { { author_id: user2.id } }

      it { is_expected.to match_array([user2, user1, external_user, omniauth_user, current_user]) }
    end
  end
end
