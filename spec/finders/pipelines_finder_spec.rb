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

      it 'selects all pipelines' do
        expect(subject).to match_array(Ci::Pipeline.all)
      end

      it 'orders in descending order on ID' do
        expect(subject).to eq(Ci::Pipeline.order(id: :desc))
      end
    end

    context 'when scope is passed' do
      context 'when selecting running' do
        let(:params) { { scope: 'running' } }

        it 'has only running status' do
          expect(subject).to match_array(Ci::Pipeline.running)
        end
      end

      context 'when selecting pending' do
        let(:params) { { scope: 'pending' } }

        it 'has only pending status' do
          expect(subject).to match_array(Ci::Pipeline.pending)
        end
      end

      context 'when selecting finished' do
        let(:params) { { scope: 'finished' } }

        it 'has only finished status' do
          expect(subject).to match_array(Ci::Pipeline.finished)
        end
      end

      context 'when selecting branches' do
        let(:params) { { scope: 'branches' } }

        it 'excludes tags' do
          expect(subject).to eq([Ci::Pipeline.where(tag: false).last])
        end
      end

      context 'when selecting tags' do
        let(:params) { { scope: 'tags' } }

        it 'excludes branches' do
          expect(subject).to eq([Ci::Pipeline.where(tag: true).last])
        end
      end
    end

    context 'when status is passed' do
      context 'when selecting running' do
        let(:params) { { status: 'running' } }

        it 'has only running status' do
          expect(subject).to match_array(Ci::Pipeline.running)
        end
      end

      context 'when selecting pending' do
        let(:params) { { status: 'pending' } }

        it 'has only pending status' do
          expect(subject).to match_array(Ci::Pipeline.pending)
        end
      end

      context 'when selecting success' do
        let(:params) { { status: 'success' } }

        it 'has only success status' do
          expect(subject).to match_array(Ci::Pipeline.success)
        end
      end

      context 'when selecting failed' do
        let(:params) { { status: 'failed' } }

        it 'has only failed status' do
          expect(subject).to match_array(Ci::Pipeline.failed)
        end
      end

      context 'when selecting canceled' do
        let(:params) { { status: 'canceled' } }

        it 'has only canceled status' do
          expect(subject).to match_array(Ci::Pipeline.canceled)
        end
      end

      context 'when selecting skipped' do
        let(:params) { { status: 'skipped' } }

        it 'has only skipped status' do
          expect(subject).to match_array(Ci::Pipeline.skipped)
        end
      end
    end 
    
    context 'when ref is passed' do
      context 'when ref exists' do
        let(:params) { { ref: 'master' } }

        it 'selects all pipelines which belong to the ref' do
          expect(subject).to match_array(Ci::Pipeline.where(ref: 'master'))
        end
      end

      context 'when ref does not exist' do
        let(:params) { { ref: 'invalid-ref' } }

        it 'selects nothing' do
          expect(subject).to be_empty
        end
      end
    end

    context 'when name is passed' do
      context 'when name exists' do
        let(:params) { { name: user1.name } }

        it 'selects all pipelines which belong to the name' do
          expect(subject).to match_array(Ci::Pipeline.where(user: user1))
        end
      end

      context 'when name does not exist' do
        let(:params) { { name: 'invalid-name' } }

        it 'selects nothing' do
          expect(subject).to be_empty
        end
      end
    end

    context 'when username is passed' do
      context 'when username exists' do
        let(:params) { { username: user1.username } }

        it 'selects all pipelines which belong to the username' do
          expect(subject).to match_array(Ci::Pipeline.where(user: user1))
        end
      end

      context 'when username does not exist' do
        let(:params) { { username: 'invalid-username' } }

        it 'selects nothing' do
          expect(subject).to be_empty
        end
      end
    end

    context 'when yaml_errors is passed' do
      context 'when yaml_errors is true' do
        let(:params) { { yaml_errors: true } }

        it 'selects only pipelines have yaml_errors' do
          expect(subject).to match_array(Ci::Pipeline.where("yaml_errors IS NOT NULL"))
        end
      end

      context 'when yaml_errors is false' do
        let(:params) { { yaml_errors: false } }

        it 'selects only pipelines do not have yaml_errors' do
          expect(subject).to match_array(Ci::Pipeline.where("yaml_errors IS NULL"))
        end
      end

      context 'when an argument is invalid' do
        let(:params) { { yaml_errors: "UnexpectedValue" } }

        it 'selects all pipelines' do
          expect(subject).to match_array(Ci::Pipeline.all)
        end
      end
    end

    context 'when order_by and sort are passed' do
      context 'when order by created_at asc' do
        let(:params) { { order_by: 'created_at', sort: 'asc' } }

        it 'sorts by created_at asc' do
          expect(subject).to eq(Ci::Pipeline.order(created_at: :asc))
        end
      end

      context 'when order by created_at desc' do
        let(:params) { { order_by: 'created_at', sort: 'desc' } }

        it 'sorts by created_at desc' do
          expect(subject).to eq(Ci::Pipeline.order(created_at: :desc))
        end
      end

      context 'when order_by does not exist' do
        let(:params) { { order_by: 'invalid_column', sort: 'desc' } }

        it 'sorts by default' do
          expect(subject).to eq(Ci::Pipeline.order(id: :desc))
        end
      end

      context 'when sort does not exist' do
        let(:params) { { order_by: 'created_at', sort: 'invalid_sort' } }

        it 'sorts by default' do
          expect(subject).to eq(Ci::Pipeline.order(id: :desc))
        end
      end
    end
  end
end
