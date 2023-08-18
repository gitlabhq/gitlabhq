# frozen_string_literal: true

require 'spec_helper'

RSpec.describe WorkItems::NamespaceWorkItemsFinder, feature_category: :team_planning do
  include AdminModeHelper

  describe '#execute' do
    let_it_be(:group) { create(:group, :public) }
    let_it_be(:sub_group) { create(:group, :private, parent: group) }
    let_it_be(:project) { create(:project, :repository, :public, group: group) }
    let_it_be(:user) { create(:user) }
    let_it_be(:reporter) { create(:user).tap { |user| group.add_reporter(user) } }
    let_it_be(:guest) { create(:user).tap { |user| group.add_guest(user) } }
    let_it_be(:guest_author) { create(:user).tap { |user| group.add_guest(user) } }
    let_it_be(:banned_user) { create(:banned_user) }

    let_it_be(:project_work_item) { create(:work_item, project: project) }
    let_it_be(:sub_group_work_item) do
      create(:work_item, namespace: sub_group, author: reporter)
    end

    let_it_be(:group_work_item) do
      create(:work_item, namespace: group, author: reporter)
    end

    let_it_be(:group_confidential_work_item, reload: true) do
      create(:work_item, :confidential, namespace: group, author: guest_author)
    end

    let_it_be(:sub_group_confidential_work_item, reload: true) do
      create(:work_item, :confidential, namespace: sub_group, author: guest_author)
    end

    let_it_be(:hidden_work_item) do
      create(:work_item, :confidential, namespace: group, author: banned_user.user)
    end

    let_it_be(:other_work_item) { create(:work_item) }
    let(:finder_params) { {} }
    let(:current_user) { user }
    let(:namespace) { nil }

    subject do
      described_class.new(current_user, finder_params.merge(
        namespace_id: namespace
      )).execute
    end

    context 'when no parent is provided' do
      it { is_expected.to be_empty }
    end

    context 'when the namespace is private' do
      let(:namespace) { sub_group }

      context 'when the user cannot read the namespace' do
        it { is_expected.to be_empty }
      end

      context 'when the user can not see confidential work_items' do
        let(:current_user) { guest }

        it { is_expected.to contain_exactly(sub_group_work_item) }

        context 'when the user is the author of the work item' do
          let(:current_user) { guest_author }

          it { is_expected.to contain_exactly(sub_group_work_item, sub_group_confidential_work_item) }
        end

        context 'when the user is assigned to a confidential work item' do
          before do
            sub_group_confidential_work_item.update!(assignees: [current_user])
          end

          it { is_expected.to contain_exactly(sub_group_work_item, sub_group_confidential_work_item) }
        end
      end

      context 'when the user can see confidential work_items' do
        let(:current_user) { reporter }

        it { is_expected.to contain_exactly(sub_group_work_item, sub_group_confidential_work_item) }
      end
    end

    context 'when the namespace is public' do
      let(:namespace) { group }

      context 'when user is admin' do
        let(:current_user) { create(:user, :admin).tap { |u| enable_admin_mode!(u) } }

        it { is_expected.to contain_exactly(group_work_item, group_confidential_work_item, hidden_work_item) }
      end

      context 'with an anonymous user' do
        let(:current_user) { nil }

        it { is_expected.to contain_exactly(group_work_item) }
      end

      context 'when the user can not see confidential work_items' do
        it { is_expected.to contain_exactly(group_work_item) }

        context 'when the user is the author of the work item' do
          let(:current_user) { guest_author }

          it { is_expected.to contain_exactly(group_work_item, group_confidential_work_item) }
        end

        context 'when the user is assigned to a confidential work item' do
          before do
            group_confidential_work_item.update!(assignees: [current_user])
          end

          it { is_expected.to contain_exactly(group_work_item, group_confidential_work_item) }
        end
      end

      context 'when the user can see confidential work_items' do
        let(:current_user) { reporter }

        it { is_expected.to contain_exactly(group_work_item, group_confidential_work_item) }
      end
    end
  end
end
