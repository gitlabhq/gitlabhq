# frozen_string_literal: true

RSpec.describe QA::Scenario::Test::Integration::ObjectStorage do
  describe '#perform' do
    it_behaves_like 'a QA scenario class' do
      let(:tags) { [:object_storage] }
    end
  end
end
