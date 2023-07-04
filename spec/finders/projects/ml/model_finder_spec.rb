# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::Ml::ModelFinder, feature_category: :mlops do
  let_it_be(:model1_a) { create(:ml_model_package) }
  let_it_be(:project) { model1_a.project }
  let_it_be(:model1_b) do
    create(:ml_model_package, name: model1_a.name, project: project)
  end

  let_it_be(:model2) do
    create(:ml_model_package, status: :pending_destruction, project: project)
  end

  let_it_be(:model3) { create(:ml_model_package) }
  let_it_be(:model4) { create(:generic_package, project: project) }

  subject { described_class.new(project).execute.to_a }

  it 'returns the most recent version of a model' do
    is_expected.to include(model1_b)
  end

  it 'does not return older versions of a model' do
    is_expected.not_to include(model1_a)
  end

  it 'does not return models pending destruction' do
    is_expected.not_to include(model2)
  end

  it 'does not return models belonging to a different project' do
    is_expected.not_to include(model3)
  end

  it 'does not return packages that are not ml_model' do
    is_expected.not_to include(model4)
  end
end
