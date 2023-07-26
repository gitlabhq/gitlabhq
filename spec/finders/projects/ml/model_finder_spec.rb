# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::Ml::ModelFinder, feature_category: :mlops do
  let_it_be(:project) { create(:project) }
  let_it_be(:model1) { create(:ml_models, :with_versions, project: project) }
  let_it_be(:model2) { create(:ml_models, :with_versions, project: project) }
  let_it_be(:model3) { create(:ml_models) }

  subject(:models) { described_class.new(project).execute.to_a }

  it 'returns models for project' do
    is_expected.to match_array([model1, model2])
  end

  it 'including the latest version', :aggregate_failures do
    expect(models[0].association_cached?(:latest_version)).to be(true)
    expect(models[1].association_cached?(:latest_version)).to be(true)
  end

  it 'does not return models belonging to a different project' do
    is_expected.not_to include(model3)
  end
end
