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
        discussion_to_resolve: 'discussion_123',
        add_related_issue: 'issue_456',
        merge_request_to_resolve_discussions_of: 'mr_789',
        observability_log_details: { log: 'details' },
        observability_metric_details: { metric: 'details' },
        observability_trace_details: { trace: 'details' },
        issue: {
          title: 'Test Issue',
          description: 'Test Description',
          confidential: 'true',
          assignee_ids: [1, 2],
          label_ids: [10, 20]
        },
        issue_type: 'issue'
      }
    end

    before do
      allow(WorkItems::TypesFilter).to receive(:allowed_types_for_issues).and_return(%w[issue incident task])
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
