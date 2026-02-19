# frozen_string_literal: true

require 'spec_helper'

RSpec.describe IssueBuildParameters, feature_category: :team_planning do
  let(:user) { instance_double(User) }
  let(:project) { instance_double(Project, group: nil, licensed_feature_available?: false) }
  let(:vulnerability) { instance_double(Vulnerability) }

  let(:controller_class) do
    Class.new do
      include IssueBuildParameters

      attr_reader :current_user, :project, :params_hash

      def initialize(current_user, project, params_hash)
        @current_user = current_user
        @project = project
        @params_hash = params_hash
      end

      def params
        ActionController::Parameters.new(@params_hash)
      end

      # rubocop: disable Gitlab/PredicateMemoization -- mock behavior
      def can?(user, ability, resource)
        @can_abilities ||= {}
        @can_abilities[[user, ability, resource]] ||= false
      end
      # rubocop: enable Gitlab/PredicateMemoization
    end
  end

  subject(:issue_build_params) { controller_class.new(user, project, params_hash) }

  describe '#build_params' do
    let(:params_hash) do
      {
        issue: {
          title: 'Test Issue',
          description: 'Test Description',
          assignee_id: '123',
          assignee_ids: [1, 2],
          confidential: 'true',
          discussion_locked: 'true',
          due_date: 'due_date',
          label_ids: [10, 20],
          lock_version: 'LV1',
          milestone_id: 'milestone_id',
          position: '999',
          state_event: 'state_event',
          task_num: '888',
          update_task: {
            index: 'update task index',
            checked: 'update task checked',
            line_number: 'update task line_number',
            line_source: 'update task line_source',
            line_sourcepos: 'update task line_sourcepos'
          },
          sentry_issue_attributes: {
            sentry_issue_identifier: 'sentry_id'
          }
        },
        add_related_issue: 'issue_456',
        discussion_to_resolve: 'discussion_123',
        issue_type: 'issue',
        merge_request_to_resolve_discussions_of: 'mr_789',
        observability_log_details: 'observability log details',
        observability_metric_details: 'observability metric details',
        observability_trace_details: 'observability trace details',
        unknow: 'value'
      }
    end

    before do
      allow(WorkItems::TypesFilter).to receive(:allowed_types_for_issues).and_return(%w[issue incident task])
    end

    it 'allowed fields', :aggregate_failures do
      result = issue_build_params.build_params

      expect(result.keys).not_to include('unknown')
      expect(result.keys).to match_array(%w[
        title
        description
        add_related_issue
        assignee_id
        assignee_ids
        confidential
        discussion_locked
        discussion_to_resolve
        due_date
        issue_type
        label_ids
        lock_version
        merge_request_to_resolve_discussions_of
        milestone_id
        observability_links
        position
        sentry_issue_attributes
        state_event
        task_num
        update_task
      ])

      expect(result['title']).to eq('Test Issue')
      expect(result['description']).to eq('Test Description')
      expect(result['assignee_id']).to eq('123')
      expect(result['assignee_ids']).to match_array([1, 2])
      expect(result['confidential']).to be(true)
      expect(result['discussion_locked']).to eq('true')
      expect(result['due_date']).to eq('due_date')
      expect(result['label_ids']).to match_array([10, 20])
      expect(result['lock_version']).to eq('LV1')
      expect(result['milestone_id']).to eq('milestone_id')
      expect(result['position']).to eq('999')
      expect(result['state_event']).to eq('state_event')
      expect(result['task_num']).to eq('888')
      expect(result['add_related_issue']).to eq('issue_456')
      expect(result['discussion_to_resolve']).to eq('discussion_123')
      expect(result['issue_type']).to eq('issue')
      expect(result.dig('update_task', 'index')).to eq('update task index')
      expect(result.dig('update_task', 'checked')).to eq('update task checked')
      expect(result.dig('update_task', 'line_number')).to eq('update task line_number')
      expect(result.dig('update_task', 'line_source')).to eq('update task line_source')
      expect(result.dig('update_task', 'line_sourcepos')).to eq('update task line_sourcepos')
      expect(result.dig('sentry_issue_attributes', 'sentry_issue_identifier')).to eq('sentry_id')
      expect(result.dig('observability_links', 'logs')).to eq('observability log details')
      expect(result.dig('observability_links', 'metrics')).to eq('observability metric details')
      expect(result.dig('observability_links', 'tracing')).to eq('observability trace details')
    end

    it 'returns merged parameters with issue_params and observability_links' do
      result = issue_build_params.build_params

      expect(result[:title]).to eq('Test Issue')
      expect(result[:description]).to eq('Test Description')
      expect(result[:discussion_to_resolve]).to eq('discussion_123')
      expect(result[:merge_request_to_resolve_discussions_of]).to eq('mr_789')
    end

    it 'converts confidential to boolean true' do
      result = issue_build_params.build_params

      expect(result[:confidential]).to be true
    end

    it 'converts confidential to boolean false' do
      params_hash[:issue][:confidential] = 'false'

      result = issue_build_params.build_params

      expect(result[:confidential]).to be false
    end

    it 'includes observability_links with metrics, logs, and tracing' do
      result = issue_build_params.build_params

      expect(result[:observability_links]).to be_a(ActionController::Parameters)
      expect(result.key?(:observability_links)).to be true
    end

    it 'permits the returned parameters' do
      result = issue_build_params.build_params

      expect(result).to be_a(ActionController::Parameters)
      expect(result.permitted?).to be true
    end

    it 'preserves assignee_ids from issue_params' do
      result = issue_build_params.build_params

      expect(result[:assignee_ids]).to match_array([1, 2])
    end

    it 'handles missing observability details gracefully' do
      params_hash.delete(:observability_log_details)
      params_hash.delete(:observability_metric_details)
      params_hash.delete(:observability_trace_details)

      result = issue_build_params.build_params

      expect(result[:observability_links]).to be_a(ActionController::Parameters)
      expect(result.key?(:observability_links)).to be true
    end
  end

  describe '#issue_params' do
    context 'with nested issue parameters' do
      let(:params_hash) do
        {
          issue: {
            title: 'Test Issue',
            description: 'Test Description',
            confidential: false
          }
        }
      end

      before do
        allow(WorkItems::TypesFilter).to receive(:allowed_types_for_issues).and_return(%w[issue incident task])
      end

      it 'returns the issue parameters' do
        result = issue_build_params.issue_params

        expect(result[:title]).to eq('Test Issue')
        expect(result[:description]).to eq('Test Description')
        expect(result[:confidential]).to be false
      end

      it 'preserves existing assignee_ids' do
        params_hash[:issue][:assignee_ids] = [1, 2, 3]

        result = issue_build_params.issue_params

        expect(result[:assignee_ids]).to match_array([1, 2, 3])
      end
    end

    context 'with top-level issue_type parameter' do
      let(:params_hash) do
        {
          issue_type: 'incident',
          issue: {
            title: 'Test Incident'
          }
        }
      end

      before do
        allow(WorkItems::TypesFilter).to receive(:allowed_types_for_issues).and_return(%w[issue incident task])
      end

      it 'uses top-level issue_type when nested issue_type is not present' do
        result = issue_build_params.issue_params

        expect(result[:issue_type]).to eq('incident')
      end

      it 'removes issue_type if not allowed' do
        allow(WorkItems::TypesFilter).to receive(:allowed_types_for_issues).and_return(%w[issue task])

        result = issue_build_params.issue_params

        expect(result.key?(:issue_type)).to be false
      end
    end

    context 'with nested issue_type parameter' do
      let(:params_hash) do
        {
          issue: {
            title: 'Test Issue',
            issue_type: 'task'
          }
        }
      end

      before do
        allow(WorkItems::TypesFilter).to receive(:allowed_types_for_issues).and_return(%w[issue incident task])
      end

      it 'uses nested issue_type' do
        result = issue_build_params.issue_params

        expect(result[:issue_type]).to eq('task')
      end

      it 'removes nested issue_type if not allowed' do
        allow(WorkItems::TypesFilter).to receive(:allowed_types_for_issues).and_return(%w[issue])

        result = issue_build_params.issue_params

        expect(result.key?(:issue_type)).to be false
      end
    end

    context 'with missing issue parameter' do
      let(:params_hash) { {} }

      before do
        allow(WorkItems::TypesFilter).to receive(:allowed_types_for_issues).and_return(%w[issue])
      end

      it 'returns empty ActionController::Parameters with default assignee_ids' do
        result = issue_build_params.issue_params

        expect(result).to be_a(ActionController::Parameters)
        expect(result[:assignee_ids]).to eq("")
      end
    end
  end
end
