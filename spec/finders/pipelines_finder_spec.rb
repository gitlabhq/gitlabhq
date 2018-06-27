require 'spec_helper'

describe PipelinesFinder do
  let(:project) { create(:project, :repository) }

  subject { described_class.new(project, params).execute }

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

    context 'when order_by and sort are specified' do
      context 'when order_by user_id' do
        let(:params) { { order_by: 'user_id', sort: 'asc' } }
        let!(:pipelines) { Array.new(2) { create(:ci_pipeline, project: project, user: create(:user)) } }

        it 'sorts as user_id: :asc' do
          is_expected.to match_array(pipelines)
        end

        context 'when sort is invalid' do
          let(:params) { { order_by: 'user_id', sort: 'invalid_sort' } }

          it 'sorts as user_id: :desc' do
            is_expected.to eq(pipelines.sort_by { |p| -p.user.id })
          end
        end
      end

      context 'when order_by is invalid' do
        let(:params) { { order_by: 'invalid_column', sort: 'asc' } }
        let!(:pipelines) { create_list(:ci_pipeline, 2, project: project) }

        it 'sorts as id: :asc' do
          is_expected.to eq(pipelines.sort_by { |p| p.id })
        end
      end

      context 'when both are nil' do
        let(:params) { { order_by: nil, sort: nil } }
        let!(:pipelines) { create_list(:ci_pipeline, 2, project: project) }

        it 'sorts as id: :desc' do
          is_expected.to eq(pipelines.sort_by { |p| -p.id })
        end
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
  end
end
