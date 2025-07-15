import { shallowMount } from '@vue/test-utils';
import { GlEmptyState, GlSprintf, GlLink } from '@gitlab/ui';

import InstanceRunnersTabEmptyState from '~/ci/runner/project_runners_settings/components/instance_runners_tab_empty_state.vue';

describe('InstanceRunnersTabEmptyState', () => {
  let wrapper;

  const createComponent = ({ props } = {}) => {
    wrapper = shallowMount(InstanceRunnersTabEmptyState, {
      propsData: {
        instanceRunnersEnabled: true,
        instanceRunnersDisabledAndUnoverridable: false,
        ...props,
      },
      stubs: {
        GlSprintf,
      },
    });
  };

  const findEmptyState = () => wrapper.findComponent(GlEmptyState);

  describe('when instance runners are enabled', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders empty state with correct title', () => {
      expect(findEmptyState().props('title')).toBe('No instance runners found');
    });

    it('renders empty state with correct description', () => {
      expect(findEmptyState().text()).toBe('This instance does not have any instance runners yet.');
    });
  });

  describe('when instance runners are disabled', () => {
    beforeEach(() => {
      createComponent({
        props: {
          instanceRunnersEnabled: false,
          instanceRunnersDisabledAndUnoverridable: false,
        },
      });
    });

    it('renders empty state with correct title', () => {
      expect(findEmptyState().props('title')).toBe('Instance runners are turned off');
    });

    it('renders empty state with correct description', () => {
      expect(findEmptyState().text()).toBe(
        'Instance runners are turned off for this project. Turn them on to use them.',
      );
    });
  });

  describe('when instance runners are disabled and unoverridable', () => {
    beforeEach(() => {
      createComponent({
        props: {
          instanceRunnersEnabled: false,
          instanceRunnersDisabledAndUnoverridable: true,
        },
      });
    });

    it('renders empty state with correct title', () => {
      expect(findEmptyState().props('title')).toBe('Instance runners are turned off');
    });

    it('renders empty state with correct description', () => {
      expect(findEmptyState().text()).toBe(
        'Instance runners are turned off in the group settings.',
      );
    });
  });

  describe('when instance runners are disabled, unoverridable, and user can change group settings', () => {
    beforeEach(() => {
      createComponent({
        props: {
          instanceRunnersEnabled: false,
          instanceRunnersDisabledAndUnoverridable: true,
          groupName: 'My group',
          groupSettingsPath: 'group/project/-/settings/ci_cd#runners-settings',
        },
      });
    });

    it('renders empty state with correct title', () => {
      expect(findEmptyState().props('title')).toBe('Instance runners are turned off');
    });

    it('renders empty state with correct description', () => {
      expect(findEmptyState().text()).toContain(
        'Instance runners are turned off in the group settings.',
      );
      expect(findEmptyState().text()).toContain('Go to My group to enable them.');

      expect(findEmptyState().findComponent(GlLink).text()).toBe('My group');
      expect(findEmptyState().findComponent(GlLink).props('href')).toBe(
        'group/project/-/settings/ci_cd#runners-settings',
      );
    });
  });
});
