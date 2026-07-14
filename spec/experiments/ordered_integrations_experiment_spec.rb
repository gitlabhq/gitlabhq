# frozen_string_literal: true

require 'spec_helper'

RSpec.describe OrderedIntegrationsExperiment, :experiment, feature_category: :integrations do
  it_behaves_like 'defines control and candidate variants'

  it 'resolves the ordered_integrations experiment name to this class' do
    expect(described_class).to eq(Gitlab::Experiment.constantize(:ordered_integrations))
  end
end
