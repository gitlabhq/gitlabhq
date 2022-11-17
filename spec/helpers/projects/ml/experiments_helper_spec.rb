# frozen_string_literal: true

require 'rspec'

require 'spec_helper'
require 'mime/types'

RSpec.describe Projects::Ml::ExperimentsHelper do
  let_it_be(:project) { build(:project, :private) }
  let_it_be(:experiment) { build(:ml_experiments, user_id: project.creator, project: project) }
  let_it_be(:candidates) do
    create_list(:ml_candidates, 2, experiment: experiment, user: project.creator).tap do |c|
      c[0].params.create!([{ name: 'param1', value: 'p1' }, { name: 'param2', value: 'p2' }])
      c[0].metrics.create!(
        [{ name: 'metric1', value: 0.1 }, { name: 'metric2', value: 0.2 }, { name: 'metric3', value: 0.3 }]
      )

      c[1].params.create!([{ name: 'param2', value: 'p3' }, { name: 'param3', value: 'p4' }])
      c[1].metrics.create!(name: 'metric3', value: 0.4)
    end
  end

  describe '#candidates_table_items' do
    subject { helper.candidates_table_items(candidates) }

    it 'creates the correct model for the table' do
      expected_value = [
        { 'param1' => 'p1', 'param2' => 'p2', 'metric1' => '0.1000', 'metric2' => '0.2000', 'metric3' => '0.3000' },
        { 'param2' => 'p3', 'param3' => 'p4', 'metric3' => '0.4000' }
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
end
