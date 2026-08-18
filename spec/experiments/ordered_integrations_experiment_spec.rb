# frozen_string_literal: true

require 'spec_helper'

RSpec.describe OrderedIntegrationsExperiment, :experiment, feature_category: :integrations do
  it_behaves_like 'defines control and candidate variants'

  it 'resolves the ordered_integrations experiment name to this class' do
    expect(described_class).to eq(Gitlab::Experiment.constantize(:ordered_integrations))
  end

  describe '#key_for' do
    subject(:experiment) { described_class.new('namespaced/stub') }

    it 'generates legacy MD5 hashes' do
      expect(experiment.key_for(foo: :bar)).to eq('6f9ac12afdb9b58c2f19a136d09f9153')
    end
  end
end
