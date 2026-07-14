# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Issuables::AssigneeFilter, feature_category: :team_planning do
  let_it_be(:user, freeze: false) { create(:user) }
  let_it_be(:other_user, freeze: false) { create(:user) }

  let(:params) { {} }

  subject(:filter) { described_class.new(params: params, current_user: user) }

  describe '#filter' do
    let_it_be(:project, freeze: false) { create(:project) }
    let_it_be(:issue_assigned_to_user, freeze: false) { create(:issue, project: project, assignees: [user]) }
    let_it_be(:issue_assigned_to_other, freeze: false) { create(:issue, project: project, assignees: [other_user]) }
    let_it_be(:issues, freeze: false) { Issue.where(id: [issue_assigned_to_user.id, issue_assigned_to_other.id]) }

    context 'when assignee_id and assignee_username are both provided' do
      let(:params) { { assignee_id: user.id, assignee_username: other_user.username } }

      it 'uses assignee_id and ignores assignee_username' do
        expect(filter.filter(issues)).to contain_exactly(issue_assigned_to_user)
      end
    end

    context 'when assignee_ids and assignee_username are both provided' do
      let(:params) { { assignee_ids: [user.id], assignee_username: other_user.username } }

      it 'uses assignee_ids and ignores assignee_username' do
        expect(filter.filter(issues)).to contain_exactly(issue_assigned_to_user)
      end
    end

    context 'when assignee_id is "ME"' do
      let(:params) { { assignee_id: 'ME' } }

      it 'returns issues assigned to the current user' do
        expect(filter.filter(issues)).to contain_exactly(issue_assigned_to_user)
      end

      context 'when current_user is nil' do
        subject(:filter) { described_class.new(params: params, current_user: nil) }

        it 'returns no issues' do
          expect(filter.filter(issues)).to be_empty
        end
      end
    end

    # Group handle scenarios: assignee_username=@group triggers OR-semantics expansion
    context 'with a group handle assignee_username' do
      let_it_be(:group, freeze: false) { create(:group, :private) }

      before_all do
        group.add_developer(user)
        group.add_developer(other_user)
      end

      context 'when assignee_id and a group handle are both provided' do
        # Real attack vector: assignee_id satisfies includes_user? (bypassing confidentiality),
        # while the group handle would normally expand results to all group members via OR.
        # The fix prevents mixing: explicit ID params take priority, group expansion is skipped.
        let(:params) { { assignee_id: user.id, assignee_username: group.to_reference } }

        it 'uses assignee_id and does not expand to group members' do
          expect(filter.filter(issues)).to contain_exactly(issue_assigned_to_user)
        end
      end

      context 'when assignee_ids and a group handle are both provided' do
        let(:params) { { assignee_ids: [user.id], assignee_username: group.to_reference } }

        it 'uses assignee_ids and does not expand to group members' do
          expect(filter.filter(issues)).to contain_exactly(issue_assigned_to_user)
        end
      end

      context 'when only a group handle is provided' do
        let(:params) { { assignee_username: group.to_reference } }

        it 'returns issues assigned to any group member' do
          expect(filter.filter(issues)).to contain_exactly(issue_assigned_to_user, issue_assigned_to_other)
        end
      end
    end
  end

  describe '#includes_user?' do
    context 'when no assignee param is present' do
      it 'returns false' do
        expect(filter.includes_user?(user)).to be(false)
      end
    end

    context 'when filtering exclusively by the given user via assignee_id' do
      let(:params) { { assignee_id: user.id } }

      it 'returns true' do
        expect(filter.includes_user?(user)).to be(true)
      end
    end

    context 'when filtering via FILTER_ME' do
      let(:params) { { assignee_id: Issuables::BaseFilter::FILTER_ME } }

      it 'returns true for the current user' do
        expect(filter.includes_user?(user)).to be true
      end

      it 'returns false for a different user' do
        expect(filter.includes_user?(other_user)).to be false
      end
    end

    context 'when filtering exclusively by the given user via assignee_ids' do
      let(:params) { { assignee_ids: [user.id] } }

      it 'returns true' do
        expect(filter.includes_user?(user)).to be(true)
      end
    end

    context 'when filtering by multiple assignees including the given user' do
      let(:params) { { assignee_ids: [user.id, other_user.id] } }

      it 'returns true because AND semantics guarantee all results are assigned to the user' do
        expect(filter.includes_user?(user)).to be(true)
      end
    end

    context 'when filtering by a different user only' do
      let(:params) { { assignee_id: other_user.id } }

      it 'returns false' do
        expect(filter.includes_user?(user)).to be(false)
      end
    end

    context 'when filtering by assignee_username for the given user' do
      let(:params) { { assignee_username: user.username } }

      it 'returns true' do
        expect(filter.includes_user?(user)).to be(true)
      end
    end

    context 'when filtering by assignee_username for a different user' do
      let(:params) { { assignee_username: other_user.username } }

      it 'returns false' do
        expect(filter.includes_user?(user)).to be(false)
      end
    end

    context 'when filtering by a group handle assignee_username' do
      let(:params) { { assignee_username: group.to_reference } }

      let_it_be(:group, freeze: false) { create(:group, :private) }

      before_all { group.add_developer(user) }

      it 'returns false because User.by_username resolves nothing for a group handle' do
        expect(filter.includes_user?(user)).to be(false)
      end
    end
  end
end
