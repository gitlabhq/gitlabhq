# frozen_string_literal: true

require_relative '../../caproni/scripts/write_local_config'

RSpec.describe WriteLocalConfig do
  describe '.build' do
    let(:domain) { '172.17.0.3.nip.io' }

    it 'carries the domain and nothing else when no job opted in' do
      expect(described_class.build(domain: domain)).to eq(
        'variables' => { 'BASE_DOMAIN' => domain }
      )
    end

    # Unset arrives as nil, blank as ""; both mean no subpath
    it 'treats an empty relative URL root as no opt-in' do
      expect(described_class.build(domain: domain, relative_url_root: '')).not_to have_key('extends')
    end

    it 'extends the subpath fragment when a root is set' do
      expect(described_class.build(domain: domain, relative_url_root: '/relative'))
        .to include('extends' => ['caproni.relative-url.yaml'])
    end

    it 'extends the OAuth fragment only for the OAuth scenario' do
      expect(described_class.build(domain: domain, qa_scenario: 'Test::Integration::OAuth'))
        .to include('extends' => ['caproni.github-oauth.yaml'])
      expect(described_class.build(domain: domain, qa_scenario: 'Test::Instance::All'))
        .not_to have_key('extends')
    end

    it 'extends every fragment a job opted into' do
      config = described_class.build(
        domain: domain, relative_url_root: '/relative', qa_scenario: 'Test::Integration::OAuth'
      )

      expect(config['extends']).to contain_exactly(
        'caproni.github-oauth.yaml', 'caproni.relative-url.yaml'
      )
    end
  end
end
