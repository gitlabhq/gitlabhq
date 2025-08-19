import { mount } from '@vue/test-utils';
import { GlTruncate, GlLink } from '@gitlab/ui';
import DeploymentInfo from '~/vue_merge_request_widget/components/deployment/deployment_info.vue';
import TimeAgoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';
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

  const findTruncate = () => wrapper.findComponent(GlTruncate);
  const findLink = () => wrapper.findComponent(GlLink);
  const findDeploymentTime = () => wrapper.findComponent(TimeAgoTooltip);

  beforeEach(() => {
    factory();
  });

  it('should render gl-truncate for environment name', () => {
    expect(findTruncate().exists()).toBe(true, 'We should use gl-truncate for environment name');
    expect(findTruncate().props()).toEqual({
      text: deploymentMockData.name,
      withTooltip: true,
      position: 'middle',
    });
  });

  it('should have a link with a correct href to deployed environment', () => {
    expect(findLink().exists()).toBe(
      true,
      'We should have gl-link pointing to deployed environment',
    );
    expect(findLink().attributes().href).toBe(deploymentMockData.url);
  });

  it('should display correct deployment time', () => {
    expect(findDeploymentTime().props('time')).toBe(deploymentMockData.deployed_at);
  });
});
