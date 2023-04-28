import { shallowMount } from '@vue/test-utils';

import { GlButton } from '@gitlab/ui';
import RunnerKubernetesInstructions from '~/vue_shared/components/runner_instructions/instructions/runner_kubernetes_instructions.vue';

describe('RunnerKubernetesInstructions', () => {
  let wrapper;

  const createComponent = () => {
    wrapper = shallowMount(RunnerKubernetesInstructions, {});
  };

  const findButton = () => wrapper.findComponent(GlButton);

  beforeEach(() => {
    createComponent();
  });

  it('renders contents', () => {
    expect(wrapper.text()).toContain(
      'To install Runner in Kubernetes follow the instructions described in the GitLab documentation.',
    );
    expect(wrapper.text()).toContain('View installation instructions');
    expect(wrapper.text()).toContain('Close');
  });

  it('renders link', () => {
    expect(findButton().attributes('href')).toBe(
      'https://docs.gitlab.com/runner/install/kubernetes.html',
    );
  });
});
