# frozen_string_literal: true

require 'yaml'

# The OpenBao fragment spells out names other files own: the database, its conn secret and
# the cluster service, all derived from values/gitlab-dev-stack.yaml and caproni.yaml. A
# rename in either would only show up as a failed Rails preflight.
RSpec.describe 'OpenBao fragment' do
  let(:caproni_dir) { File.expand_path('../../caproni', __dir__) }
  let(:config) { YAML.safe_load_file(File.join(caproni_dir, 'caproni.yaml')) }
  let(:fragment) { YAML.safe_load_file(File.join(caproni_dir, 'caproni.openbao.yaml')) }
  let(:dev_stack) { YAML.safe_load_file(File.join(caproni_dir, 'values/gitlab-dev-stack.yaml')) }

  let(:values) do
    fragment.dig('deployers', 'gitlab', 'helm', 'dynamic_overrides')
      .select { |o| o['type'] == 'inline' }
      .map { |o| o['value_map'] }
      .reduce({}, :merge)
  end

  let(:dev_stack_release) { config.dig('deployers', 'gitlab-dev-stack', 'helm', 'release', 'name') }
  let(:dev_stack_namespace) { config.dig('deployers', 'gitlab-dev-stack', 'helm', 'namespace') }
  let(:cluster) { dev_stack.dig('postgres', 'clusters').first }
  let(:openbao_db) { cluster['databases'].find { |db| db['name'] == 'openbao' } }

  it 'has gitlab-dev-stack provision the openbao database with the user the fragment uses' do
    expect(openbao_db).not_to be_nil, 'values/gitlab-dev-stack.yaml declares no openbao database'
    expect(openbao_db['owner']).to eq(values['global.openbao.psql.username'])
    expect(values['global.openbao.psql.database']).to eq('openbao')
  end

  it 'reads the conn secret gitlab-dev-stack writes for that database' do
    expect(values['global.openbao.psql.password.secret'])
      .to eq("#{dev_stack_release}-#{cluster['name']}-openbao-conn")
  end

  it 'reaches PostgreSQL through the dev-stack cluster service' do
    expect(values['global.openbao.psql.host'])
      .to eq("#{dev_stack_release}-#{cluster['name']}-rw.#{dev_stack_namespace}.svc")
  end

  it 'keeps the base hostnames and adds openbao for update-etc-hosts' do
    base = config.dig('cluster', 'network', 'additional_hostnames')

    expect(fragment.dig('cluster', 'network', 'additional_hostnames'))
      .to match_array(base + ['openbao.${BASE_DOMAIN}'])
  end
end
