require 'spec_helper'

describe HasEnvironmentScope do
  subject { build(:ci_variable) }

  it { is_expected.to allow_value('*').for(:environment_scope) }
  it { is_expected.to allow_value('review/*').for(:environment_scope) }
  it { is_expected.not_to allow_value('').for(:environment_scope) }
  it { is_expected.not_to allow_value('!!()()').for(:environment_scope) }

  it do
    is_expected.to validate_uniqueness_of(:key)
      .scoped_to(:project_id, :environment_scope)
      .with_message(/\(\w+\) has already been taken/)
  end

  describe '.on_environment' do
    let(:project) { create(:project) }
    let!(:cluster1) { create(:cluster, projects: [project], environment_scope: '*') }
    let!(:cluster2) { create(:cluster, projects: [project], environment_scope: 'product/*') }
    let!(:cluster3) { create(:cluster, projects: [project], environment_scope: 'staging/*') }
    let(:environment_name) { 'product/*' }

    it 'returns scoped objects' do
      expect(project.clusters.on_environment(environment_name)).to eq([cluster1, cluster2])
    end
  end

  describe '#environment_scope=' do
    context 'when the new environment_scope is nil' do
      it 'strips leading and trailing whitespaces' do
        subject.environment_scope = nil

        expect(subject.environment_scope).to eq('')
      end
    end

    context 'when the new environment_scope has leadind and trailing whitespaces' do
      it 'strips leading and trailing whitespaces' do
        subject.environment_scope = ' * '

        expect(subject.environment_scope).to eq('*')
      end
    end
  end
end
