# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Autocomplete::UsersFinder, feature_category: :team_planning do
  # TODO update when multiple owners are possible in projects
  # https://gitlab.com/gitlab-org/gitlab/-/issues/21432

  describe '#execute' do
    let_it_be(:user1) { create(:user, name: 'zzzzzname', username: 'johndoe') }
    let_it_be(:blocked_user) { create(:user, :blocked, username: 'blocked_user') }
    let_it_be(:banned_user) { create(:user, :banned, username: 'banned_user') }
    let_it_be(:external_user) { create(:user, :external) }
    let_it_be(:omniauth_user) { create(:omniauth_user, provider: 'twitter', extern_uid: '123456') }

    let(:current_user) { create(:user) }
    let(:params) { {} }

    let_it_be(:project) { nil }
    let_it_be(:group) { nil }

    subject { described_class.new(params: params, current_user: current_user, project: project, group: group).execute.to_a }

    before do
      stub_feature_flags(group_users_autocomplete_using_batch_reduction: false)
    end

    context 'when current_user not passed or nil' do
      let(:current_user) { nil }

      it { is_expected.to match_array([]) }
    end

    context 'when project passed' do
      let_it_be(:project) { create(:project) }

      it { is_expected.to match_array([project.first_owner]) }

      context 'when author_id passed' do
        context 'and author is active' do
          let(:params) { { author_id: user1.id } }

          it { is_expected.to match_array([project.first_owner, user1]) }
        end

        context 'and author is blocked' do
          let(:params) { { author_id: blocked_user.id } }

          it { is_expected.to match_array([project.first_owner]) }
        end

        context 'and author is banned' do
          let(:params) { { author_id: banned_user.id } }

          it { is_expected.to match_array([project.first_owner]) }
        end
      end

      context 'searching with less than 3 characters' do
        let(:params) { { search: 'zz' } }

        before do
          project.add_guest(user1)
        end

        it 'allows partial matches' do
          expect(subject).to contain_exactly(user1)
        end
      end
    end

    context 'when group passed and project not passed' do
      let_it_be(:group) { create(:group, :public) }

      before_all do
        group.add_members([user1], GroupMember::DEVELOPER)
      end

      it { is_expected.to match_array([user1]) }

      context 'searching with less than 3 characters' do
        let(:params) { { search: 'zz' } }

        it 'allows partial matches' do
          expect(subject).to contain_exactly(user1)
        end
      end

      context 'when querying the users with cross joins disabled' do
        before do
          stub_const("#{described_class.name}::BATCH_SIZE", 5)
          stub_const("#{described_class.name}::LIMIT", 3)
          stub_feature_flags(group_users_autocomplete_using_batch_reduction: true)
        end

        # Testing the 0 batches case
        context 'when the group has no matching users' do
          let(:params) { { search: 'non_matching_query' } }

          it { is_expected.to eq([]) }
        end

        context 'when the group is smaller than the batch size' do
          let(:params) { { search: 'zzz' } }
          let_it_be(:user2) { create(:user, name: 'zzz', username: 'zzz_john_doe') }

          before do
            group.add_developer(user2)
          end

          specify do
            expect_next_instance_of(described_class) do |instance|
              expect(instance).to receive(:users_relation).once.and_call_original
            end

            # order is important. user2 comes first because it matches the username
            is_expected.to eq([user2, user1])
          end
        end

        context 'when the group has more users than the batch size' do
          let_it_be(:users_a) do
            build_list(:user, 2) do |record, i|
              record.assign_attributes({ name: "Oliver Doe #{i}", username: "oliver_#{i}" })
              record.save!
            end
          end

          let_it_be(:users_b) do
            build_list(:user, 4) do |record, i|
              record.assign_attributes({ name: "Peter Doe #{i}", username: "peter_#{i}" })
              record.save!
            end
          end

          let_it_be(:user2) { create(:user, name: 'John Foobar', username: 'john_foobar') }
          let_it_be(:user3) { create(:user, name: 'Johanna Doe', username: 'johanna_doe') }
          let_it_be(:user4) { create(:user, name: 'Oliver Foobar', username: 'oliver_foobar') }
          let_it_be(:non_member) { create(:user, name: 'Johanna Doe', username: 'johanna_doe_2') }

          before do
            group.members.delete_all
            group.add_members(users_a, GroupMember::DEVELOPER)
            group.add_members(users_b, GroupMember::DEVELOPER)
            group.add_members([user2, user3, user4], GroupMember::DEVELOPER)
          end

          context 'when the query matches several users that span over different batches' do
            let(:params) { { search: 'Oliver' } }

            specify do
              # the relation is called once per batch (2 batches), and once at the end to reduce the batches
              expect_next_instance_of(described_class) do |instance|
                expect(instance).to receive(:users_relation).exactly(3).times.and_call_original
              end

              is_expected.to eq(users_a + [user4])
            end
          end

          context 'when the query matches only one user' do
            let(:params) { { search: 'johanna_doe' } }

            it { is_expected.to eq([user3]) }
          end
        end
      end
    end

    context 'when passed a subgroup' do
      let(:grandparent) { create(:group, :public) }
      let(:parent) { create(:group, :public, parent: grandparent) }
      let(:child) { create(:group, :public, parent: parent) }
      let(:group) { parent }
      let(:child_project) { create(:project, group: group) }

      let!(:grandparent_user) { create(:group_member, :developer, group: grandparent).user }
      let!(:parent_user) { create(:group_member, :developer, group: parent).user }
      let!(:child_user) { create(:group_member, :developer, group: child).user }
      let!(:child_project_user) { create(:project_member, :developer, project: child_project).user }

      it 'includes users from parent groups, descendant groups, and descendant projects' do
        expect(subject).to contain_exactly(
          grandparent_user,
          parent_user,
          child_user,
          child_project_user
        )
      end

      context 'when querying the users with cross joins disabled' do
        let(:params) { { search: 'zzz' } }
        let_it_be(:user2) { create(:user, name: 'John Doe', username: 'zzz1') }
        let_it_be(:user3) { create(:user, name: 'John Doe', username: 'zzz2') }
        let_it_be(:user4) { create(:user, name: 'John Doe', username: 'zzz3') }

        before do
          stub_const("#{described_class.name}::BATCH_SIZE", 3)
          stub_const("#{described_class.name}::LIMIT", 2)
          stub_feature_flags(group_users_autocomplete_using_batch_reduction: true)
          GroupMember.delete_all
          ProjectMember.delete_all
          group.add_members([user2, user3, user4], GroupMember::DEVELOPER)
          parent.add_members([user2, user3, user4], GroupMember::DEVELOPER)
          grandparent.add_members([user2, user3, user4], GroupMember::DEVELOPER)
        end

        it 'deduplicates the user_ids in batches to reduce database queries' do
          expect_next_instance_of(described_class) do |instance|
            expect(instance).to receive(:users_relation).once.and_call_original
          end

          # order is important. user2 comes first because it matches the username
          is_expected.to eq([user2, user3])
        end
      end
    end

    it { is_expected.to match_array([user1, external_user, omniauth_user, current_user]) }

    context 'when filtered by search' do
      let(:params) { { search: 'johndoe' } }

      it { is_expected.to match_array([user1]) }

      context 'searching with less than 3 characters' do
        let(:params) { { search: 'zz' } }

        it 'does not allow partial matches' do
          expect(subject).to be_empty
        end
      end
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
      let(:current_user) { blocked_user }
      let(:params) { { current_user: true } }

      it { is_expected.to match_array([blocked_user, user1, external_user, omniauth_user]) }
    end

    context 'when filtered by author_id' do
      let(:params) { { author_id: user1.id } }

      it { is_expected.to match_array([user1, external_user, omniauth_user, current_user]) }
    end

    it 'preloads the status association' do
      associations = subject.map { |user| user.association(:status) }
      expect(associations).to all(be_loaded)
    end

    context 'when filtered by state' do
      context "searching without states" do
        let(:params) { { states: nil } }

        it { is_expected.to match_array([user1, external_user, omniauth_user, current_user]) }
      end

      context "searching with states=active" do
        let(:params) { { states: %w[active] } }

        it { is_expected.to match_array([user1, external_user, omniauth_user, current_user]) }
      end

      context "searching with states=blocked" do
        let(:params) { { states: %w[blocked] } }

        it { is_expected.to match_array([blocked_user]) }
      end

      context "searching with states=banned" do
        let(:params) { { states: %w[banned] } }

        it { is_expected.to match_array([banned_user]) }
      end

      context "searching with states=blocked,banned" do
        let(:params) { { states: %w[blocked banned] } }

        it { is_expected.to match_array([blocked_user, banned_user]) }
      end
    end
  end
end
