require 'spec_helper'

feature 'Interchangeability between KubernetesService and Platform::Kubernetes' do
  EXCEPT_METHODS = %i[test title description help fields initialize_properties namespace namespace= api_url api_url= deprecated? deprecation_message].freeze
  EXCEPT_METHODS_GREP_V = %w[_touched? _changed? _was].freeze

  it 'Clusters::Platform::Kubernetes covers core interfaces in KubernetesService' do
    expected_interfaces = KubernetesService.instance_methods(false)
    expected_interfaces = expected_interfaces - EXCEPT_METHODS
    EXCEPT_METHODS_GREP_V.each do |g|
      expected_interfaces = expected_interfaces.grep_v(/#{Regexp.escape(g)}\z/)
    end

    expect(expected_interfaces - Clusters::Platforms::Kubernetes.instance_methods).to be_empty
  end
end
