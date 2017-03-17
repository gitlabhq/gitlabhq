require 'spec_helper'

describe PipelinesFinder do
  let(:user1) { create(:user) }
  let(:user2) { create(:user) }
  let(:project) { create(:project, :repository) }

  before do
    create(:ci_pipeline, project: project, user: user1, ref: 'v1.0.0', tag: true)
    create(:ci_pipeline, project: project, user: user1, status: 'created')
    create(:ci_pipeline, project: project, user: user1, status: 'pending')
    create(:ci_pipeline, project: project, user: user1, status: 'running')
    create(:ci_pipeline, project: project, user: user1, status: 'success')
    create(:ci_pipeline, project: project, user: user2, status: 'failed')
    create(:ci_pipeline, project: project, user: user2, status: 'canceled')
    create(:ci_pipeline, project: project, user: user2, status: 'skipped')
    create(:ci_pipeline, project: project, user: user2, yaml_errors: 'Syntax error')
  end

  subject { described_class.new(project, params).execute }

  describe "#execute" do
    context 'when nothing is passed' do
      let(:params) { {} }

      it 'returns all pipelines' do
        expect(subject).to match_array(Ci::Pipeline.all)
      end

      it 'orders in descending order on ID' do
        expect(subject).to eq(Ci::Pipeline.order(id: :desc))
      end
    end

    context 'when scope is passed' do
      context 'when scope is running' do
        let(:params) { { scope: 'running' } }

        it 'returns matched pipelines' do
          expect(subject).to match_array(Ci::Pipeline.running)
        end
      end

      context 'when scope is pending' do
        let(:params) { { scope: 'pending' } }

        it 'returns matched pipelines' do
          expect(subject).to match_array(Ci::Pipeline.pending)
        end
      end

      context 'when scope is finished' do
        let(:params) { { scope: 'finished' } }

        it 'returns matched pipelines' do
          expect(subject).to match_array(Ci::Pipeline.finished)
        end
      end

      context 'when scope is branches' do
        let(:params) { { scope: 'branches' } }

        it 'returns matched pipelines' do
          expect(subject).to eq([Ci::Pipeline.where(tag: false).last])
        end
      end

      context 'when scope is tags' do
        let(:params) { { scope: 'tags' } }

        it 'returns matched pipelines' do
          expect(subject).to eq([Ci::Pipeline.where(tag: true).last])
        end
      end
    end

    context 'when status is passed' do
      context 'when status is running' do
        let(:params) { { status: 'running' } }

        it 'returns matched pipelines' do
          expect(subject).to match_array(Ci::Pipeline.running)
        end
      end

      context 'when status is pending' do
        let(:params) { { status: 'pending' } }

        it 'returns matched pipelines' do
          expect(subject).to match_array(Ci::Pipeline.pending)
        end
      end

      context 'when status is success' do
        let(:params) { { status: 'success' } }

        it 'returns matched pipelines' do
          expect(subject).to match_array(Ci::Pipeline.success)
        end
      end

      context 'when status is failed' do
        let(:params) { { status: 'failed' } }

        it 'returns matched pipelines' do
          expect(subject).to match_array(Ci::Pipeline.failed)
        end
      end

      context 'when status is canceled' do
        let(:params) { { status: 'canceled' } }

        it 'returns matched pipelines' do
          expect(subject).to match_array(Ci::Pipeline.canceled)
        end
      end

      context 'when status is skipped' do
        let(:params) { { status: 'skipped' } }

        it 'returns matched pipelines' do
          expect(subject).to match_array(Ci::Pipeline.skipped)
        end
      end
    end 
    
    context 'when ref is passed' do
      context 'when ref exists' do
        let(:params) { { ref: 'master' } }

        it 'returns matched pipelines' do
          expect(subject).to match_array(Ci::Pipeline.where(ref: 'master'))
        end
      end

      context 'when ref does not exist' do
        let(:params) { { ref: 'invalid-ref' } }

        it 'returns empty' do
          expect(subject).to be_empty
        end
      end
    end

    context 'when name is passed' do
      context 'when name exists' do
        let(:params) { { name: user1.name } }

        it 'returns matched pipelines' do
          expect(subject).to match_array(Ci::Pipeline.where(user: user1))
        end
      end

      context 'when name does not exist' do
        let(:params) { { name: 'invalid-name' } }

        it 'returns empty' do
          expect(subject).to be_empty
        end
      end
    end

    context 'when username is passed' do
      context 'when username exists' do
        let(:params) { { username: user1.username } }

        it 'returns matched pipelines' do
          expect(subject).to match_array(Ci::Pipeline.where(user: user1))
        end
      end

      context 'when username does not exist' do
        let(:params) { { username: 'invalid-username' } }

        it 'returns empty' do
          expect(subject).to be_empty
        end
      end
    end

    context 'when yaml_errors is passed' do
      context 'when yaml_errors is true' do
        let(:params) { { yaml_errors: true } }

        it 'returns matched pipelines' do
          expect(subject).to match_array(Ci::Pipeline.where("yaml_errors IS NOT NULL"))
        end
      end

      context 'when yaml_errors is false' do
        let(:params) { { yaml_errors: false } }

        it 'returns matched pipelines' do
          expect(subject).to match_array(Ci::Pipeline.where("yaml_errors IS NULL"))
        end
      end

      context 'when yaml_errors is invalid' do
        let(:params) { { yaml_errors: "UnexpectedValue" } }

        it 'returns all pipelines' do
          expect(subject).to match_array(Ci::Pipeline.all)
        end
      end
    end

    context 'when order_by and sort are passed' do
      context 'when order_by and sort are valid' do
        let(:params) { { order_by: 'user_id', sort: 'asc' } }

        it 'sorts pipelines by default' do
          expect(subject).to eq(Ci::Pipeline.order(user_id: :asc))
        end
      end

      context 'when order_by is invalid' do
        let(:params) { { order_by: 'invalid_column', sort: 'asc' } }

        it 'sorts pipelines with default order_by (id:)' do
          expect(subject).to eq(Ci::Pipeline.order(id: :asc))
        end
      end

      context 'when sort is invalid' do
        let(:params) { { order_by: 'user_id', sort: 'invalid_sort' } }

        it 'sorts pipelines with default sort (:desc)' do
          expect(subject).to eq(Ci::Pipeline.order(user_id: :desc))
        end
      end

      context 'when both are nil' do
        let(:params) { { order_by: nil, sort: nil } }

        it 'sorts pipelines by default' do
          expect(subject).to eq(Ci::Pipeline.order(id: :desc))
        end
      end
    end
  end
end
