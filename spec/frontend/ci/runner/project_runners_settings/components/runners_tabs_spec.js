import { nextTick } from 'vue';
import { shallowMount } from '@vue/test-utils';
import { GlTabs } from '@gitlab/ui';
import { INSTANCE_TYPE, GROUP_TYPE, PROJECT_TYPE } from '~/ci/runner/constants';

import InstanceRunnersToggle from '~/projects/settings/components/instance_runners_toggle.vue';

import RunnersTab from '~/ci/runner/project_runners_settings/components/runners_tab.vue';
import RunnersTabs from '~/ci/runner/project_runners_settings/components/runners_tabs.vue';
import RunnerToggleAssignButton from '~/ci/runner/project_runners_settings/components/runner_toggle_assign_button.vue';

import GroupRunnersToggle from '~/ci/runner/project_runners_settings/components/group_runners_toggle.vue';
import GroupRunnersTabEmptyState from '~/ci/runner/project_runners_settings/components/group_runners_tab_empty_state.vue';
import InstanceRunnersTabEmptyState from '~/ci/runner/project_runners_settings/components/instance_runners_tab_empty_state.vue';
import ProjectRunnersTabEmptyState from '~/ci/runner/project_runners_settings/components/project_runners_tab_empty_state.vue';

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
        instanceRunnersEnabled: true,
        instanceRunnersDisabledAndUnoverridable: false,
        instanceRunnersUpdatePath: 'group/project/-/runners/toggle_shared_runners',
        groupName: 'My group',
        instanceRunnersGroupSettingsPath: 'group/project/-/settings/ci_cd#runners-settings',
        ...props,
      },
      stubs: {
        RunnersTab: {
          props: RunnersTab.props,
          data() {
            return { runner: mockRunner };
          },
          methods: {
            refresh() {
              // identify which tabs refreshed
              mockRefresh(this.title);
            },
          },
          template: `<div>
            <slot name="description" />
            <slot name="settings" />
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
      expect(findRunnerTabAt(0).findComponent(ProjectRunnersTabEmptyState).exists()).toBe(true);
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
      expect(mockRefresh).toHaveBeenCalledWith('Assigned project runners');
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

      expect(findRunnerTabAt(1).text()).toContain(
        'These runners are shared across projects in this group.',
      );
      expect(findRunnerTabAt(1).findComponent(GroupRunnersToggle).exists()).toEqual(true);
      expect(findRunnerTabAt(1).findComponent(GroupRunnersTabEmptyState).exists()).toEqual(true);
    });

    it('updates list and empty state on toggle', async () => {
      findRunnerTabAt(1).findComponent(GroupRunnersToggle).vm.$emit('change', false);
      await nextTick();

      expect(mockRefresh).toHaveBeenCalledTimes(1);
      expect(mockRefresh).toHaveBeenCalledWith('Group');
      expect(
        findRunnerTabAt(1).findComponent(GroupRunnersTabEmptyState).props('groupRunnersEnabled'),
      ).toEqual(false);
    });

    it('emits an error event from toggle', () => {
      findRunnerTabAt(1).findComponent(GroupRunnersToggle).vm.$emit('error', error);

      expect(wrapper.emitted().error[0]).toEqual([error]);
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
      expect(findRunnerTabAt(2).findComponent(InstanceRunnersTabEmptyState).exists()).toBe(true);
    });

    it('shows instance runners toggle', () => {
      expect(findRunnerTabAt(2).findComponent(InstanceRunnersToggle).props()).toEqual({
        groupName: 'My group',
        groupSettingsPath: 'group/project/-/settings/ci_cd#runners-settings',
        isDisabledAndUnoverridable: false,
        isEnabled: true,
        updatePath: 'group/project/-/runners/toggle_shared_runners',
      });
    });

    it('updates list and empty state on toggle', async () => {
      findRunnerTabAt(2).findComponent(InstanceRunnersToggle).vm.$emit('change', false);
      await nextTick();

      expect(mockRefresh).toHaveBeenCalledTimes(1);
      expect(mockRefresh).toHaveBeenCalledWith('Instance');
      expect(findRunnerTabAt(2).findComponent(InstanceRunnersToggle).props('isEnabled')).toEqual(
        false,
      );
    });

    it('emits an error event', () => {
      findRunnerTabAt(2).vm.$emit('error', error);

      expect(wrapper.emitted().error[0]).toEqual([error]);
    });
  });
});
