import EMPTY_STATE_SVG_URL from '@gitlab/svgs/dist/illustrations/empty-state/empty-pipeline-md.svg?url';

import { shallowMount } from '@vue/test-utils';
import { GlEmptyState } from '@gitlab/ui';
import RunnerJobsEmptyState from '~/ci/runner/components/runner_jobs_empty_state.vue';

const DEFAULT_PROPS = {
  emptyTitle: 'This runner has not run any jobs',
  emptyDescription:
    'Make sure the runner is online and available to run jobs (not paused). Jobs display here when the runner picks them up.',
};

describe('RunnerJobsEmptyStateComponent', () => {
  let wrapper;

  const mountComponent = () => {
    wrapper = shallowMount(RunnerJobsEmptyState);
  };

  const findEmptyState = () => wrapper.findComponent(GlEmptyState);

  beforeEach(() => {
    mountComponent();
  });

  describe('empty', () => {
    it('should show an empty state if it is empty', () => {
      const emptyState = findEmptyState();

      expect(emptyState.props('svgPath')).toBe(EMPTY_STATE_SVG_URL);
      expect(emptyState.props('title')).toBe(DEFAULT_PROPS.emptyTitle);
      expect(emptyState.text()).toContain(DEFAULT_PROPS.emptyDescription);
    });
  });
});
