import { shallowMount } from '@vue/test-utils';

import { GlButton } from '@gitlab/ui';
import RunnerDockerInstructions from '~/vue_shared/components/runner_instructions/instructions/runner_docker_instructions.vue';

describe('RunnerDockerInstructions', () => {
  let wrapper;

  const createComponent = () => {
    wrapper = shallowMount(RunnerDockerInstructions, {});
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
      'https://docs.gitlab.com/runner/install/docker.html',
    );
  });
});
