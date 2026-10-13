# frozen_string_literal: true

require 'yaml'

# The OIDC consumer fragment spells out the primary's webservice Service, which caproni.yaml
# names. A rename there would only show up as a failed sign-in in cng-oauth-caproni.
RSpec.describe 'OIDC consumer fragment' do
  let(:caproni_dir) { File.expand_path('../../caproni', __dir__) }
  let(:config) { YAML.safe_load_file(File.join(caproni_dir, 'caproni.yaml')) }
  let(:fragment) { YAML.safe_load_file(File.join(caproni_dir, 'caproni.oidc-consumer.yaml')) }
  let(:primary) { config.dig('deployers', 'gitlab', 'helm') }

  # Caproni appends additional_hostnames across extends, so repeating the base ones duplicates them
  it 'adds only the consumer hostname for update-etc-hosts' do
    expect(fragment.dig('cluster', 'network', 'additional_hostnames')).to eq(['consumer.${BASE_DOMAIN}'])
  end

  it "calls the primary's Workhorse Service from inside the cluster" do
    expect(fragment.dig('variables', 'OIDC_IDP_INTERNAL_URL'))
      .to eq("http://#{primary.dig('release', 'name')}-webservice-default.#{primary['namespace']}.svc:8181")
  end
end
