# frozen_string_literal: true

RSpec.describe QA::Scenario::Test::Integration::Mattermost do
  describe '#perform' do
    it_behaves_like 'a QA scenario class' do
      let(:args) { { gitlab_address: 'http://gitlab_address', mattermost_address: 'http://mattermost_address' } }
      let(:named_options) { %w[--address http://gitlab_address --mattermost-address http://mattermost_address] }
      let(:tags) { [:mattermost] }
      let(:options) { ['path1'] }

      it 'defines mattermost address' do
        subject.perform(args)

        expect(scenario).to have_received(:define)
          .with(:mattermost_address, 'http://mattermost_address')
      end
    end
  end
end
