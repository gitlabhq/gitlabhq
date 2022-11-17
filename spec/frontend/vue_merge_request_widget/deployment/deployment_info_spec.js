import { mount } from '@vue/test-utils';
import { GlTruncate, GlLink } from '@gitlab/ui';
import DeploymentInfo from '~/vue_merge_request_widget/components/deployment/deployment_info.vue';
import { deploymentMockData } from './deployment_mock_data';

// This component is well covered in ./deployment_spec.js
// more component-specific tests are added below
describe('Deployment Info component', () => {
  let wrapper;

  const defaultDeploymentInfoOptions = {
    computedDeploymentStatus: 'computed deployment status',
    deployment: deploymentMockData,
    showMetrics: false,
  };

  const factory = (options = {}) => {
    const componentProps = { ...defaultDeploymentInfoOptions, ...options };
    const componentOptions = { propsData: componentProps };
    wrapper = mount(DeploymentInfo, componentOptions);
  };

  beforeEach(() => {
    factory();
  });

  it('should render gl-truncate for environment name', () => {
    const envNameComponent = wrapper.findComponent(GlTruncate);
    expect(envNameComponent.exists()).toBe(true, 'We should use gl-truncate for environment name');
    expect(envNameComponent.props()).toEqual({
      text: deploymentMockData.name,
      withTooltip: true,
      position: 'middle',
    });
  });

  it('should have a link with a correct href to deployed environment', () => {
    const envLink = wrapper.findComponent(GlLink);
    expect(envLink.exists()).toBe(true, 'We should have gl-link pointing to deployed environment');
    expect(envLink.attributes().href).toBe(deploymentMockData.url);
  });
});
