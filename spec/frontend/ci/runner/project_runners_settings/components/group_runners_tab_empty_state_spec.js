import { shallowMount } from '@vue/test-utils';
import { GlEmptyState, GlSprintf, GlLink } from '@gitlab/ui';

import GroupRunnersTabEmptyState from '~/ci/runner/project_runners_settings/components/group_runners_tab_empty_state.vue';

describe('GroupRunnersTabEmptyState', () => {
  let wrapper;

  const createComponent = ({ props, provide } = {}) => {
    wrapper = shallowMount(GroupRunnersTabEmptyState, {
      provide: {
        canCreateRunnerForGroup: true,
        groupRunnersPath: '/group/runners',
        ...provide,
      },
      propsData: {
        groupRunnersEnabled: true,
        ...props,
      },
      stubs: {
        GlSprintf,
      },
    });
  };

  const findEmptyState = () => wrapper.findComponent(GlEmptyState);

  describe('when group runners are enabled', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders empty state with correct title', () => {
      expect(findEmptyState().props('title')).toBe('No group runners found');
    });

    it('renders empty state with correct description', () => {
      expect(findEmptyState().text()).toContain('This group does not have any group runners yet.');
      expect(findEmptyState().text()).toContain(
        "To register them, go to the group's Runners page.",
      );
      expect(findEmptyState().findComponent(GlLink).props('href')).toBe('/group/runners');
    });

    describe('when use cannot add runners to group', () => {
      beforeEach(() => {
        createComponent({ provide: { canCreateRunnerForGroup: false } });
      });

      it('renders empty state with correct description', () => {
        expect(findEmptyState().text()).toContain(
          'This group does not have any group runners yet.',
        );
        expect(findEmptyState().text()).toContain('Ask your group owner to set up a group runner.');
        expect(findEmptyState().findComponent(GlLink).exists()).toBe(false);
      });
    });
  });

  describe('when group runners are disabled', () => {
    beforeEach(() => {
      createComponent({ props: { groupRunnersEnabled: false } });
    });

    it('renders empty state with correct title', () => {
      expect(findEmptyState().props('title')).toBe('Group runners are turned off');
    });

    it('renders empty state with correct description', () => {
      expect(findEmptyState().text()).toBe(
        'Group runners are turned off for this project. Turn them on to use them.',
      );
    });
  });
});
