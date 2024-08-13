# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mutations::AlertManagement::Alerts::SetAssignees, feature_category: :api do
  include GraphqlHelpers

  let_it_be(:starting_assignee) { create(:user) }
  let_it_be(:unassigned_user) { create(:user) }
  let_it_be(:alert) { create(:alert_management_alert, assignees: [starting_assignee]) }
  let_it_be(:project) { alert.project }

  let(:current_user) { starting_assignee }
  let(:assignee_usernames) { [unassigned_user.username] }
  let(:operation_mode) { nil }

  let(:args) do
    {
      project_path: project.full_path,
      iid: alert.iid,
      assignee_usernames: assignee_usernames,
      operation_mode: operation_mode
    }
  end

  before_all do
    project.add_developer(starting_assignee)
    project.add_developer(unassigned_user)
  end

  specify { expect(described_class).to require_graphql_authorizations(:update_alert_management_alert) }

  describe '#resolve' do
    let(:expected_assignees) { [unassigned_user] }

    subject(:resolve) { mutation_for(project, current_user).resolve(args) }

    shared_examples 'successful resolution' do
      after do
        alert.assignees = [starting_assignee]
      end

      it 'successfully resolves' do
        expect(resolve).to eq(alert: alert.reload, errors: [])
        expect(alert.assignees).to eq(expected_assignees)
      end
    end

    shared_examples 'noop' do
      it 'makes no changes' do
        original_assignees = alert.assignees

        expect(resolve).to eq(alert: alert.reload, errors: [])
        expect(alert.assignees).to eq(original_assignees)
      end
    end

    context 'when operation mode is not specified' do
      it_behaves_like 'successful resolution'
      it_behaves_like 'an incident management tracked event', :incident_management_alert_assigned

      it_behaves_like 'Snowplow event tracking with RedisHLL context' do
        let(:namespace) { project.namespace.reload }
        let(:category) { described_class.to_s }
        let(:user) { current_user }
        let(:action) { 'incident_management_alert_assigned' }
        let(:label) { 'redis_hll_counters.incident_management.incident_management_total_unique_counts_monthly' }
      end
    end

    context 'when user does not have permission to update alerts' do
      let(:current_user) { create(:user) }

      it 'raises an error if the resource is not accessible to the user' do
        expect { subject }.to raise_error(Gitlab::Graphql::Errors::ResourceNotAvailable)
      end
    end

    context 'for APPEND operation' do
      let(:operation_mode) { Types::MutationOperationModeEnum.enum[:append] }

      # Only allow a single assignee
      context 'when a different user is already assigned' do
        it_behaves_like 'noop'
      end

      context 'when no users are specified' do
        let(:assignee_usernames) { [] }

        it_behaves_like 'noop'
      end

      context 'when a user is specified and no user is assigned' do
        before do
          alert.assignees = []
        end

        it_behaves_like 'successful resolution'
      end

      context 'when the specified user is already assigned to the alert' do
        let(:assignee_usernames) { [starting_assignee.username] }

        it_behaves_like 'noop'
      end
    end

    context 'for REPLACE operation' do
      let(:operation_mode) { Types::MutationOperationModeEnum.enum[:replace] }

      context 'when a different user is already assigned' do
        it_behaves_like 'successful resolution'
      end

      context 'when no users are specified' do
        let(:assignee_usernames) { [] }
        let(:expected_assignees) { [] }

        it_behaves_like 'successful resolution'
      end

      context 'when a user is specified and no user is assigned' do
        before do
          alert.assignees = []
        end

        it_behaves_like 'successful resolution'
      end

      context 'when the specified user is already assigned to the alert' do
        let(:assignee_usernames) { [starting_assignee.username] }

        it_behaves_like 'noop'
      end

      context 'when multiple users are specified' do
        let(:assignees) { [starting_assignee, unassigned_user] }
        let(:assignee_usernames) { assignees.map(&:username) }
        let(:expected_assignees) { [assignees.last] }

        it_behaves_like 'successful resolution'
      end
    end

    context 'for REMOVE operation' do
      let(:operation_mode) { Types::MutationOperationModeEnum.enum[:remove] }

      context 'when a different user is already assigned' do
        it_behaves_like 'noop'
      end

      context 'when no users are specified' do
        let(:assignee_usernames) { [] }

        it_behaves_like 'noop'
      end

      context 'when a user is specified and no user is assigned' do
        before do
          alert.assignees = []
        end

        it_behaves_like 'noop'
      end

      context 'when the specified user is already assigned to the alert' do
        let(:assignee_usernames) { [starting_assignee.username] }
        let(:expected_assignees) { [] }

        it_behaves_like 'successful resolution'
      end
    end
  end

  def mutation_for(project, _user)
    described_class.new(object: project, context: query_context, field: nil)
  end
end
