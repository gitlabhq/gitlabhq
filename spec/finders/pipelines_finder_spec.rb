# frozen_string_literal: true

require 'spec_helper'

describe PipelinesFinder do
  let(:project) { create(:project, :public, :repository) }
  let(:current_user) { nil }
  let(:params) { {} }

  subject { described_class.new(project, current_user, params).execute }

  describe "#execute" do
    context 'when params is empty' do
      let(:params) { {} }
      let!(:pipelines) { create_list(:ci_pipeline, 2, project: project) }

      it 'returns all pipelines' do
        is_expected.to match_array(pipelines)
      end
    end

    %w[running pending].each do |target|
      context "when scope is #{target}" do
        let(:params) { { scope: target } }
        let!(:pipeline) { create(:ci_pipeline, project: project, status: target) }

        it 'returns matched pipelines' do
          is_expected.to eq([pipeline])
        end
      end
    end

    context 'when scope is finished' do
      let(:params) { { scope: 'finished' } }
      let!(:pipelines) do
        [create(:ci_pipeline, project: project, status: 'success'),
         create(:ci_pipeline, project: project, status: 'failed'),
         create(:ci_pipeline, project: project, status: 'canceled')]
      end

      it 'returns matched pipelines' do
        is_expected.to match_array(pipelines)
      end
    end

    context 'when scope is branches or tags' do
      let!(:pipeline_branch) { create(:ci_pipeline, project: project) }
      let!(:pipeline_tag) { create(:ci_pipeline, project: project, ref: 'v1.0.0', tag: true) }

      context 'when scope is branches' do
        let(:params) { { scope: 'branches' } }

        it 'returns matched pipelines' do
          is_expected.to eq([pipeline_branch])
        end
      end

      context 'when scope is tags' do
        let(:params) { { scope: 'tags' } }

        it 'returns matched pipelines' do
          is_expected.to eq([pipeline_tag])
        end
      end
    end

    HasStatus::AVAILABLE_STATUSES.each do |target|
      context "when status is #{target}" do
        let(:params) { { status: target } }
        let!(:pipeline) { create(:ci_pipeline, project: project, status: target) }

        before do
          exception_status = HasStatus::AVAILABLE_STATUSES - [target]
          create(:ci_pipeline, project: project, status: exception_status.first)
        end

        it 'returns matched pipelines' do
          is_expected.to eq([pipeline])
        end
      end
    end

    context 'when ref is specified' do
      let!(:pipeline) { create(:ci_pipeline, project: project) }

      context 'when ref exists' do
        let(:params) { { ref: 'master' } }

        it 'returns matched pipelines' do
          is_expected.to eq([pipeline])
        end
      end

      context 'when ref does not exist' do
        let(:params) { { ref: 'invalid-ref' } }

        it 'returns empty' do
          is_expected.to be_empty
        end
      end
    end

    context 'when name is specified' do
      let(:user) { create(:user) }
      let!(:pipeline) { create(:ci_pipeline, project: project, user: user) }

      context 'when name exists' do
        let(:params) { { name: user.name } }

        it 'returns matched pipelines' do
          is_expected.to eq([pipeline])
        end
      end

      context 'when name does not exist' do
        let(:params) { { name: 'invalid-name' } }

        it 'returns empty' do
          is_expected.to be_empty
        end
      end
    end

    context 'when username is specified' do
      let(:user) { create(:user) }
      let!(:pipeline) { create(:ci_pipeline, project: project, user: user) }

      context 'when username exists' do
        let(:params) { { username: user.username } }

        it 'returns matched pipelines' do
          is_expected.to eq([pipeline])
        end
      end

      context 'when username does not exist' do
        let(:params) { { username: 'invalid-username' } }

        it 'returns empty' do
          is_expected.to be_empty
        end
      end
    end

    context 'when yaml_errors is specified' do
      let!(:pipeline1) { create(:ci_pipeline, project: project, yaml_errors: 'Syntax error') }
      let!(:pipeline2) { create(:ci_pipeline, project: project) }

      context 'when yaml_errors is true' do
        let(:params) { { yaml_errors: true } }

        it 'returns matched pipelines' do
          is_expected.to eq([pipeline1])
        end
      end

      context 'when yaml_errors is false' do
        let(:params) { { yaml_errors: false } }

        it 'returns matched pipelines' do
          is_expected.to eq([pipeline2])
        end
      end

      context 'when yaml_errors is invalid' do
        let(:params) { { yaml_errors: "invalid-yaml_errors" } }

        it 'returns all pipelines' do
          is_expected.to match_array([pipeline1, pipeline2])
        end
      end
    end

    context 'when updated_at filters are specified' do
      let(:params) { { updated_before: 1.day.ago, updated_after: 3.days.ago } }
      let!(:pipeline1) { create(:ci_pipeline, project: project, updated_at: 2.days.ago) }
      let!(:pipeline2) { create(:ci_pipeline, project: project, updated_at: 4.days.ago) }
      let!(:pipeline3) { create(:ci_pipeline, project: project, updated_at: 1.hour.ago) }

      it 'returns deployments with matched updated_at' do
        is_expected.to match_array([pipeline1])
      end
    end

    context 'when sha is specified' do
      let!(:pipeline) { create(:ci_pipeline, project: project, sha: '97de212e80737a608d939f648d959671fb0a0142') }

      context 'when sha exists' do
        let(:params) { { sha: '97de212e80737a608d939f648d959671fb0a0142' } }

        it 'returns matched pipelines' do
          is_expected.to eq([pipeline])
        end
      end

      context 'when sha does not exist' do
        let(:params) { { sha: 'invalid-sha' } }

        it 'returns empty' do
          is_expected.to be_empty
        end
      end
    end

    context 'when the project has limited access to pipelines' do
      let(:project) { create(:project, :private, :repository) }
      let(:current_user) { create(:user) }
      let!(:pipelines) { create_list(:ci_pipeline, 2, project: project) }

      context 'when the user has access' do
        before do
          project.add_developer(current_user)
        end

        it 'is expected to return pipelines' do
          is_expected.to contain_exactly(*pipelines)
        end
      end

      context 'the user is not allowed to read pipelines' do
        it 'returns empty' do
          is_expected.to be_empty
        end
      end
    end

    describe 'ordering' do
      using RSpec::Parameterized::TableSyntax

      let(:params) { { order_by: order_by, sort: sort } }

      let!(:pipeline_1) { create(:ci_pipeline, :scheduled, project: project, iid: 11, ref: 'master', created_at: Time.now, updated_at: Time.now, user: create(:user)) }
      let!(:pipeline_2) { create(:ci_pipeline, :created, project: project, iid: 12, ref: 'feature', created_at: 1.day.ago, updated_at: 2.hours.ago, user: create(:user)) }
      let!(:pipeline_3) { create(:ci_pipeline, :success, project: project, iid: 8, ref: 'patch', created_at: 2.days.ago, updated_at: 1.hour.ago, user: create(:user)) }

      where(:order_by, :sort, :ordered_pipelines) do
        'id'         | 'asc'  | [:pipeline_1, :pipeline_2, :pipeline_3]
        'id'         | 'desc' | [:pipeline_3, :pipeline_2, :pipeline_1]
        'ref'        | 'asc'  | [:pipeline_2, :pipeline_1, :pipeline_3]
        'ref'        | 'desc' | [:pipeline_3, :pipeline_1, :pipeline_2]
        'status'     | 'asc'  | [:pipeline_2, :pipeline_1, :pipeline_3]
        'status'     | 'desc' | [:pipeline_3, :pipeline_1, :pipeline_2]
        'updated_at' | 'asc'  | [:pipeline_2, :pipeline_3, :pipeline_1]
        'updated_at' | 'desc' | [:pipeline_1, :pipeline_3, :pipeline_2]
        'user_id'    | 'asc'  | [:pipeline_1, :pipeline_2, :pipeline_3]
        'user_id'    | 'desc' | [:pipeline_3, :pipeline_2, :pipeline_1]
        'invalid'    | 'asc'  | [:pipeline_1, :pipeline_2, :pipeline_3]
        'id'         | 'err'  | [:pipeline_3, :pipeline_2, :pipeline_1]
      end

      with_them do
        it 'returns the pipelines ordered' do
          expect(subject).to eq(ordered_pipelines.map { |name| public_send(name) })
        end
      end
    end
  end
end
