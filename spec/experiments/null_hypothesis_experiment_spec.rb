# frozen_string_literal: true

require 'spec_helper'

RSpec.describe NullHypothesisExperiment, :experiment, feature_category: :acquisition do
  it_behaves_like 'defines control and candidate variants'

  it 'resolves the null_hypothesis experiment name to this class' do
    expect(described_class).to eq(Gitlab::Experiment.constantize(:null_hypothesis))
  end

  it 'declares user as its context key' do
    expect(described_class.context_keys).to eq(%i[user])
  end
end
