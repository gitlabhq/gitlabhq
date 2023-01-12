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
    expect(wrapper.text().replace(/\s+/g, ' ')).toMatchSnapshot();
  });

  it('renders link', () => {
    expect(findButton().attributes('href')).toBe(
      'https://docs.gitlab.com/runner/install/kubernetes.html',
    );
  });
});
