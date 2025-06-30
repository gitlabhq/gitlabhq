import { shallowMount } from '@vue/test-utils';
import { GlEmptyState, GlSprintf } from '@gitlab/ui';

import ProjectRunnersTabEmptyState from '~/ci/runner/project_runners_settings/components/project_runners_tab_empty_state.vue';

describe('ProjectRunnersTabEmptyState', () => {
  let wrapper;

  const createComponent = () => {
    wrapper = shallowMount(ProjectRunnersTabEmptyState, {
      stubs: {
        GlSprintf,
      },
    });
  };

  const findEmptyState = () => wrapper.findComponent(GlEmptyState);

  beforeEach(() => {
    createComponent();
  });

  it('displays correct title', () => {
    expect(findEmptyState().props('title')).toBe('No project runners found');
  });

  it('displays correct description text', () => {
    expect(findEmptyState().text()).toContain(
      'This project does not have any project runners yet.',
    );
    expect(findEmptyState().text()).toContain('To add them, select Create project runner.');
  });
});
