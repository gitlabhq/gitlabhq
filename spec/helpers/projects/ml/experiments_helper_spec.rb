# frozen_string_literal: true

require 'rspec'

require 'spec_helper'
require 'mime/types'

RSpec.describe Projects::Ml::ExperimentsHelper, feature_category: :mlops do
  let_it_be(:project) { create(:project, :private) }
  let_it_be(:experiment) { create(:ml_experiments, user_id: project.creator, project: project) }
  let_it_be(:candidate0) do
    create(:ml_candidates, :with_artifact, experiment: experiment, user: project.creator).tap do |c|
      c.params.build([{ name: 'param1', value: 'p1' }, { name: 'param2', value: 'p2' }])
      c.metrics.create!(
        [{ name: 'metric1', value: 0.1 }, { name: 'metric2', value: 0.2 }, { name: 'metric3', value: 0.3 }]
      )
    end
  end

  let_it_be(:candidate1) do
    create(:ml_candidates, experiment: experiment, user: project.creator).tap do |c|
      c.params.build([{ name: 'param2', value: 'p3' }, { name: 'param3', value: 'p4' }])
      c.metrics.create!(name: 'metric3', value: 0.4)
    end
  end

  let_it_be(:candidates) { [candidate0, candidate1] }

  describe '#candidates_table_items' do
    subject { helper.candidates_table_items(candidates) }

    it 'creates the correct model for the table' do
      expected_value = [
        { 'param1' => 'p1', 'param2' => 'p2', 'metric1' => '0.1000', 'metric2' => '0.2000', 'metric3' => '0.3000',
          'artifact' => "/#{project.full_path}/-/packages/#{candidate0.artifact.id}",
          'details' => "/#{project.full_path}/-/ml/candidates/#{candidate0.iid}" },
        { 'param2' => 'p3', 'param3' => 'p4', 'metric3' => '0.4000',
          'artifact' => nil, 'details' => "/#{project.full_path}/-/ml/candidates/#{candidate1.iid}" }
      ]

      expect(Gitlab::Json.parse(subject)).to match_array(expected_value)
    end
  end

  describe '#unique_logged_names' do
    context 'when for params' do
      subject { Gitlab::Json.parse(helper.unique_logged_names(candidates, &:params)) }

      it { is_expected.to match_array(%w[param1 param2 param3]) }
    end

    context 'when latest_metrics is passed' do
      subject { Gitlab::Json.parse(helper.unique_logged_names(candidates, &:latest_metrics)) }

      it { is_expected.to match_array(%w[metric1 metric2 metric3]) }
    end
  end

  describe '#candidate_as_data' do
    let(:candidate) { candidate0 }

    subject { Gitlab::Json.parse(helper.candidate_as_data(candidate)) }

    it 'generates the correct params' do
      expect(subject['params']).to include(
        hash_including('name' => 'param1', 'value' => 'p1'),
        hash_including('name' => 'param2', 'value' => 'p2')
      )
    end

    it 'generates the correct metrics' do
      expect(subject['metrics']).to include(
        hash_including('name' => 'metric1', 'value' => 0.1),
        hash_including('name' => 'metric2', 'value' => 0.2),
        hash_including('name' => 'metric3', 'value' => 0.3)
      )
    end

    it 'generates the correct info' do
      expected_info = {
        'iid' => candidate.iid,
        'path_to_artifact' => "/#{project.full_path}/-/packages/#{candidate.artifact.id}",
        'experiment_name' => candidate.experiment.name,
        'path_to_experiment' => "/#{project.full_path}/-/ml/experiments/#{experiment.iid}",
        'status' => 'running'
      }

      expect(subject['info']).to include(expected_info)
    end
  end
end
