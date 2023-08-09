# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::Packages::PipelinesFinder, feature_category: :package_registry do
  subject { described_class.new(pipeline_ids).execute }

  let_it_be(:project) { create(:project) }
  let_it_be(:p1) { create(:ci_pipeline, project: project) }
  let_it_be(:p2) { create(:ci_pipeline, project: project) }
  let_it_be(:p3) { create(:ci_pipeline, project: project) }

  let(:pipeline_ids) { [p1.id, p3.id] }

  describe '#execute' do
    it 'returns only pipelines that match the given IDs, in descending order' do
      expect(subject.map(&:id)).to eq([p3.id, p1.id])
    end

    it 'returns only selected columns' do
      expect(subject.first.attributes.keys.map(&:to_sym)).to eq(::Packages::PipelinesFinder::COLUMNS)
    end
  end
end
