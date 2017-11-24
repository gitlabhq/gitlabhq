require 'spec_helper'

feature 'Interchangeability between KubernetesService and Platform::Kubernetes' do
  let!(:project) { create(:project, :repository) }

  EXCEPT_METHODS = %i[test title description help fields initialize_properties namespace namespace= api_url api_url=]
  EXCEPT_METHODS_GREP_V = %w[_touched? _changed? _was]

  it 'Clusters::Platform::Kubernetes covers core interfaces in KubernetesService' do
    expected_interfaces = KubernetesService.instance_methods(false)
    expected_interfaces = expected_interfaces - EXCEPT_METHODS
    EXCEPT_METHODS_GREP_V.each do |g|
      expected_interfaces = expected_interfaces.grep_v(/#{Regexp.escape(g)}\z/)
    end
    
    expect(expected_interfaces - Clusters::Platforms::Kubernetes.instance_methods).to be_empty
  end

  shared_examples 'selects kubernetes instance' do
    context 'when user configured kubernetes from Integration > Kubernetes' do
      let!(:kubernetes_service) { create(:kubernetes_service, project: project) }

      it { is_expected.to eq(kubernetes_service) }
    end

    context 'when user configured kubernetes from CI/CD > Clusters' do
      let!(:cluster) { create(:cluster, :provided_by_gcp, projects: [project]) }
      let(:platform_kubernetes) { cluster.platform_kubernetes }

      it { is_expected.to eq(platform_kubernetes) }
    end
  end

  describe 'Project#deployment_service' do
    subject { project.deployment_service }

    it_behaves_like 'selects kubernetes instance'
  end

  describe 'Project#kubernetes_service' do
    subject { project.kubernetes_service }

    it_behaves_like 'selects kubernetes instance'
  end
end
