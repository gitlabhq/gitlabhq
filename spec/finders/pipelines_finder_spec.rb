require 'spec_helper'

describe PipelinesFinder do
  let!(:user1) { create(:user) }
  let!(:user2) { create(:user) }
  let!(:project) { create(:project, :repository) }

  let!(:dummy_pipelines) do
    {
      tag:          create(:ci_pipeline, project: project, user: user1, created_at:  9.minutes.ago, ref: 'v1.0.0'),
      created:      create(:ci_pipeline, project: project, user: user1, created_at:  8.minutes.ago, status: 'created'),
      pending:      create(:ci_pipeline, project: project, user: user1, created_at:  7.minutes.ago, status: 'pending'),
      running:      create(:ci_pipeline, project: project, user: user1, created_at:  6.minutes.ago, status: 'running'),
      success:      create(:ci_pipeline, project: project, user: user1, created_at:  5.minutes.ago, status: 'success'),
      failed:       create(:ci_pipeline, project: project, user: user2, created_at:  4.minutes.ago, status: 'failed'),
      canceled:     create(:ci_pipeline, project: project, user: user2, created_at:  3.minutes.ago, status: 'canceled'),
      skipped:      create(:ci_pipeline, project: project, user: user2, created_at:  2.minutes.ago, status: 'skipped'),
      yaml_errors:  create(:ci_pipeline, project: project, user: user2, created_at:  1.minute.ago,  yaml_errors: 'Syntax error'),
    }
  end

  subject { described_class.new(project, params).execute }

  describe "#execute" do
    context 'when nothing is passed' do
      let(:params) { {} }

      it 'selects all pipelines' do
        expect(subject.count).to be dummy_pipelines.count
        expect(subject).to match_array dummy_pipelines.values
      end

      it 'orders in descending order on ID' do
        expect(subject.map(&:id)).to eq dummy_pipelines.values.map(&:id).sort.reverse
      end
    end

    context 'when a scope is passed' do
      context 'when selecting running' do
        let(:params) { { scope: 'running' } }

        it 'has only running status' do
          expect(subject.map(&:status)).to include('running')
        end
      end

      context 'when selecting pending' do
        let(:params) { { scope: 'pending' } }

        it 'has only pending status' do
          expect(subject.map(&:status)).to include('pending')
        end
      end

      context 'when selecting finished' do
        let(:params) { { scope: 'finished' } }

        it 'has only finished status' do
          expect(subject.map(&:status)).to match_array %w[success canceled failed]
        end
      end

      context 'when selecting branches' do
        let(:params) { { scope: 'branches' } }

        it 'excludes tags' do
          expect(subject.count).to be 1
          expect(subject).not_to include dummy_pipelines[:tag]
          expect(subject.map(&:ref)).to include('master')
        end
      end

      context 'when selecting tags' do
        let(:params) { { scope: 'tags' } }

        it 'excludes branches' do
          expect(subject.count).to be 1
          expect(subject).to include dummy_pipelines[:tag]
          expect(subject.map(&:ref)).not_to include('master')
        end
      end
    end

    context 'when a status is passed' do
      context 'when selecting running' do
        let(:params) { { scope: 'running' } }

        it 'has only running status' do
          expect(subject.map(&:status)).to include('running')
        end
      end

      context 'when selecting pending' do
        let(:params) { { scope: 'pending' } }

        it 'has only pending status' do
          expect(subject.map(&:status)).to include('pending')
        end
      end

      context 'when selecting success' do
        let(:params) { { scope: 'success' } }

        it 'has only success status' do
          expect(subject.map(&:status)).to include('success')
        end
      end

      context 'when selecting failed' do
        let(:params) { { scope: 'failed' } }

        it 'has only failed status' do
          expect(subject.map(&:status)).to include('failed')
        end
      end

      context 'when selecting canceled' do
        let(:params) { { scope: 'canceled' } }

        it 'has only canceled status' do
          expect(subject.map(&:status)).to include('canceled')
        end
      end

      context 'when selecting skipped' do
        let(:params) { { scope: 'skipped' } }

        it 'has only skipped status' do
          expect(subject.map(&:status)).to include('skipped')
        end
      end
    end 
    
    context 'when a ref is passed' do
      context 'when a ref exists' do
        let(:params) { { ref: 'master' } }

        it 'selects all pipelines which belong to the ref' do
          expected = dummy_pipelines.except(:tag)
          expect(subject).to match_array expected.values
        end
      end

      context 'when a ref does not exist' do
        let(:params) { { ref: 'unique-ref' } }

        it 'selects nothing' do
          expect(subject).to be_empty
        end
      end
    end  

    context 'when a username is passed' do
      context 'when a username exists' do
        let(:params) { { username: user1.name } }

        it 'selects all pipelines which belong to the username' do
          expected = dummy_pipelines.except(:failed).except(:canceled).except(:skipped).except(:yaml_errors)
          expect(subject).to match_array expected.values
        end
      end

      context 'when a username does not exist' do
        let(:params) { { username: 'unique-username' } }

        it 'selects nothing' do
          expect(subject).to be_empty
        end
      end
    end  

    context 'when a yaml_errors is passed' do
      context 'when yaml_errors is true' do
        let(:params) { { yaml_errors: true } }

        it 'selects only pipelines have yaml_errors' do
          expect(subject.count).to be 1
          expect(subject.first).to eq dummy_pipelines[:yaml_errors]
        end
      end

      context 'when yaml_errors is false' do
        let(:params) { { yaml_errors: false } }

        it 'selects only pipelines do not have yaml_errors' do
          expected = dummy_pipelines.except(:yaml_errors)
          expect(subject.count).to be expected.count
          expect(subject).to match_array expected.values
        end
      end

      context 'when an argument is invalid' do
        let(:params) { { yaml_errors: "UnexpectedValue" } }

        it 'selects all pipelines' do
          expect(subject).to match_array dummy_pipelines.values
        end
      end
    end

    context 'when a order_by and sort are passed' do
      context 'when order by created_at asc' do
        let(:params) { { order_by: 'created_at', sort: 'asc' } }

        it 'sorts by created_at asc' do
          expect(subject.first).to eq dummy_pipelines[:tag]
          expect(subject.last).to eq dummy_pipelines[:yaml_errors]
        end
      end

      context 'when order by created_at desc' do
        let(:params) { { order_by: 'created_at', sort: 'desc' } }

        it 'sorts by created_at desc' do
          expect(subject.first).to eq dummy_pipelines[:yaml_errors]
          expect(subject.last).to eq dummy_pipelines[:tag]
        end
      end

      context 'when order_by does not exist' do
        let(:params) { { order_by: 'abnormal_column', sort: 'desc' } }

        it 'sorts by default' do
          expect(subject.map(&:id)).to eq dummy_pipelines.values.map(&:id).sort.reverse
        end
      end

      context 'when sort does not exist' do
        let(:params) { { order_by: 'created_at', sort: 'abnormal_sort' } }

        it 'sorts by default' do
          expect(subject.map(&:id)).to eq dummy_pipelines.values.map(&:id).sort.reverse
        end
      end
    end
  end
end
