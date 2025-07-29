import { shallowMount } from '@vue/test-utils';
import { GlEmptyState } from '@gitlab/ui';

import AssignableRunnersTabEmptyState from '~/ci/runner/project_runners_settings/components/assignable_runners_tab_empty_state.vue';

describe('AssignableRunnersTabEmptyState', () => {
  let wrapper;

  const createComponent = () => {
    wrapper = shallowMount(AssignableRunnersTabEmptyState, {});
  };

  const findEmptyState = () => wrapper.findComponent(GlEmptyState);

  describe('when rendered', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders empty state with correct title', () => {
      expect(findEmptyState().props('title')).toBe('No project runners found');
    });

    it('renders empty state with correct description', () => {
      expect(findEmptyState().text()).toContain(
        'No project runners are available to be assigned to this project.',
      );
    });
  });
});
