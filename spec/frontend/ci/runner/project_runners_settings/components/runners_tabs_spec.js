import { nextTick } from 'vue';
import { shallowMount } from '@vue/test-utils';
import { GlTabs } from '@gitlab/ui';
import { INSTANCE_TYPE, GROUP_TYPE, PROJECT_TYPE } from '~/ci/runner/constants';

import RunnersTab from '~/ci/runner/project_runners_settings/components/runners_tab.vue';
import RunnersTabs from '~/ci/runner/project_runners_settings/components/runners_tabs.vue';
import RunnerToggleAssignButton from '~/ci/runner/project_runners_settings/components/runner_toggle_assign_button.vue';

import { projectRunnersData } from 'jest/ci/runner/mock_data';

const mockRunner = projectRunnersData.data.project.runners.edges[0].node;

const error = new Error('Test error');

describe('RunnersTabs', () => {
  let wrapper;
  let mockRefresh;
  let mockShowToast;

  const createComponent = ({ props } = {}) => {
    wrapper = shallowMount(RunnersTabs, {
      propsData: {
        projectFullPath: 'group/project',
        ...props,
      },
      stubs: {
        RunnersTab: {
          props: RunnersTab.props,
          data() {
            return { runner: mockRunner };
          },
          methods: {
            refresh: mockRefresh,
          },
          template: `<div>
            <slot name="empty" />
            <slot name="other-runner-actions" :runner="runner"></slot>
          </div>`,
        },
      },
      mocks: {
        $toast: { show: mockShowToast },
      },
    });
  };

  const findTabs = () => wrapper.findComponent(GlTabs);
  const findRunnerTabs = () => wrapper.findAllComponents(RunnersTab);
  const findRunnerTabAt = (i) => findRunnerTabs().at(i);
  const findRunnerToggleAssignButtonAt = (i) =>
    findRunnerTabAt(i).findComponent(RunnerToggleAssignButton);

  beforeEach(() => {
    mockRefresh = jest.fn();
    mockShowToast = jest.fn();

    createComponent();
  });

  it('renders tabs container', () => {
    expect(findTabs().exists()).toBe(true);
  });

  it('renders the correct number of tabs', () => {
    expect(findRunnerTabs()).toHaveLength(3);
  });

  describe('Assigned project runners tab', () => {
    it('renders the tab content', () => {
      expect(findRunnerTabAt(0).props()).toMatchObject({
        title: 'Assigned project runners',
        runnerType: PROJECT_TYPE,
        projectFullPath: 'group/project',
      });
      expect(findRunnerTabAt(0).text()).toBe(
        'No project runners found, you can create one by selecting "New project runner".',
      );
    });

    it('renders unassign button', () => {
      expect(findRunnerToggleAssignButtonAt(0).props()).toEqual({
        projectFullPath: 'group/project',
        runner: mockRunner,
        assigns: false,
      });
    });

    it('does not render unassign button for owner project', () => {
      createComponent({
        props: {
          projectFullPath: mockRunner.ownerProject.fullPath,
        },
      });

      expect(findRunnerToggleAssignButtonAt(0).exists()).toBe(false);
    });

    it('refreshes project tabs after unassigning', async () => {
      await findRunnerToggleAssignButtonAt(0).vm.$emit('done', { message: 'Runner unassigned.' });

      await nextTick();

      expect(mockShowToast).toHaveBeenCalledWith('Runner unassigned.');

      expect(mockRefresh).toHaveBeenCalledTimes(1);
    });

    it('emits an error event', () => {
      findRunnerTabAt(0).vm.$emit('error', error);

      expect(wrapper.emitted().error[0]).toEqual([error]);
    });
  });

  describe('Group tab', () => {
    it('renders the tab content', () => {
      expect(findRunnerTabAt(1).props()).toMatchObject({
        title: 'Group',
        runnerType: GROUP_TYPE,
        projectFullPath: 'group/project',
      });
      expect(findRunnerTabAt(1).text()).toBe('No group runners found.');
    });

    it('emits an error event', () => {
      findRunnerTabAt(1).vm.$emit('error', error);

      expect(wrapper.emitted().error[0]).toEqual([error]);
    });
  });

  describe('Instance tab', () => {
    it('renders the tab content', () => {
      expect(findRunnerTabAt(2).props()).toMatchObject({
        title: 'Instance',
        runnerType: INSTANCE_TYPE,
        projectFullPath: 'group/project',
      });
      expect(findRunnerTabAt(2).text()).toBe('No instance runners found.');
    });

    it('emits an error event', () => {
      findRunnerTabAt(2).vm.$emit('error', error);

      expect(wrapper.emitted().error[0]).toEqual([error]);
    });
  });
});
