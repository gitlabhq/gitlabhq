import { shallowMount } from '@vue/test-utils';

import { GlButton } from '@gitlab/ui';
import RunnerKubernetesInstructions from '~/ci/runner/components/registration/runner_instructions/instructions/runner_kubernetes_instructions.vue';
import { DOCS_URL } from 'jh_else_ce/lib/utils/url_utility';

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
    expect(findButton().attributes('href')).toBe(`${DOCS_URL}/runner/install/kubernetes.html`);
  });
});
