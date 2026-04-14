import { nextTick } from 'vue';
import { GlTabs } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { INSTANCE_TYPE, GROUP_TYPE, PROJECT_TYPE } from '~/ci/runner/constants';

import InstanceRunnersToggle from '~/projects/settings/components/instance_runners_toggle.vue';

import RunnersTab from '~/ci/runner/project_runners_settings/components/runners_tab.vue';
import RunnersTabs from '~/ci/runner/project_runners_settings/components/runners_tabs.vue';
import GroupRunnersToggle from '~/ci/runner/project_runners_settings/components/group_runners_toggle.vue';

import ProjectRunnersTabEmptyState from '~/ci/runner/project_runners_settings/components/project_runners_tab_empty_state.vue';
import AssignableRunnersTabEmptyState from '~/ci/runner/project_runners_settings/components/assignable_runners_tab_empty_state.vue';
import GroupRunnersTabEmptyState from '~/ci/runner/project_runners_settings/components/group_runners_tab_empty_state.vue';
import InstanceRunnersTabEmptyState from '~/ci/runner/project_runners_settings/components/instance_runners_tab_empty_state.vue';

import { projectRunnersData } from 'jest/ci/runner/mock_data';

const mockRunner = projectRunnersData.data.project.runners.edges[0].node;

const error = new Error('Test error');
const defaultProvide = {
  canAssignRunners: true,
  canUnassignRunners: true,
  canToggleGroupRunners: true,
  canToggleInstanceRunners: true,
  isGroupRunnersEnabled: true,
};

describe('RunnersTabs', () => {
  let wrapper;
  let mockRefresh;
  let mockShowToast;

  const createComponent = ({ props, runner = mockRunner, provide } = {}) => {
    wrapper = shallowMountExtended(RunnersTabs, {
      propsData: {
        projectFullPath: 'group/project',
        instanceRunnersEnabled: true,
        instanceRunnersDisabledAndUnoverridable: false,
        instanceRunnersUpdatePath: 'group/project/-/runners/toggle_shared_runners',
        groupName: 'My group',
        instanceRunnersGroupSettingsPath: 'group/project/-/settings/ci_cd#runners-settings',
        ...props,
      },
      provide: { ...defaultProvide, ...provide },
      stubs: {
        RunnersTab: {
          props: RunnersTab.props,
          data() {
            return { runner };
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
  const findRunnerTab = (testid) => wrapper.findByTestId(testid);
  const findRunnerTabs = () => wrapper.findAllComponents(RunnersTab);
  const findRunnerToggleAssignButton = (testid) => wrapper.findByTestId(testid);

  beforeEach(() => {
    mockRefresh = jest.fn();
    mockShowToast = jest.fn();

    createComponent();
  });

  it('renders tabs container', () => {
    expect(findTabs().exists()).toBe(true);
  });

  it('renders the correct number of tabs', () => {
    expect(findRunnerTabs()).toHaveLength(4);
  });

  describe('Assigned project runners tab', () => {
    it('renders the tab content', () => {
      expect(findRunnerTab('project-runners-tab').props()).toMatchObject({
        title: 'Assigned project runners',
        runnerType: PROJECT_TYPE,
        projectFullPath: 'group/project',
      });
      expect(
        findRunnerTab('project-runners-tab').findComponent(ProjectRunnersTabEmptyState).exists(),
      ).toBe(true);
    });

    it('renders unassign button', () => {
      expect(findRunnerToggleAssignButton('runner-unassign-button').props()).toEqual({
        projectFullPath: 'group/project',
        runner: mockRunner,
        assigns: false,
      });
    });

    describe('canUnassignRunners is false', () => {
      it('does not render unassign button', () => {
        createComponent({ runner: mockRunner, provide: { canUnassignRunners: false } });

        expect(findRunnerToggleAssignButton('runner-unassign-button').exists()).toBe(false);
      });
    });

    it('renders unassign button even if owner project is unknown to the user', () => {
      const { ownerProject, ...mockRunner2 } = mockRunner;

      createComponent({
        runner: mockRunner2,
      });

      expect(findRunnerToggleAssignButton('runner-unassign-button').exists()).toBe(true);
    });

    it('does not render unassign button for owner project', () => {
      createComponent({
        props: {
          projectFullPath: mockRunner.ownerProject.fullPath,
        },
      });

      expect(findRunnerToggleAssignButton('runner-unassign-button').exists()).toBe(false);
    });

    it('emits an error event', () => {
      findRunnerTab('project-runners-tab').vm.$emit('error', error);

      expect(wrapper.emitted().error[0]).toEqual([error]);
    });

    describe('when runner is unassigned', () => {
      beforeEach(async () => {
        findRunnerToggleAssignButton('runner-unassign-button').vm.$emit('done', {
          message: 'Runner unassigned.',
        });
        await nextTick();
      });

      it('refreshes project tabs after assigning', () => {
        expect(mockRefresh).toHaveBeenCalledTimes(2);
        expect(mockRefresh).toHaveBeenCalledWith('Assigned project runners');
        expect(mockRefresh).toHaveBeenCalledWith('Other available project runners');
      });

      it('shows confirmation toast', () => {
        expect(mockShowToast).toHaveBeenCalledWith('Runner unassigned.');
      });
    });
  });

  describe('Available project runners tab', () => {
    it('renders the tab content', () => {
      expect(findRunnerTab('other-project-runners-tab').props()).toMatchObject({
        title: 'Other available project runners',
        runnerType: PROJECT_TYPE,
        projectFullPath: 'group/project',
        useAssignableQuery: true,
      });
      expect(
        findRunnerTab('other-project-runners-tab')
          .findComponent(AssignableRunnersTabEmptyState)
          .exists(),
      ).toBe(true);
    });

    it('renders assign button', () => {
      expect(findRunnerToggleAssignButton('runner-assign-button').props()).toEqual({
        projectFullPath: 'group/project',
        runner: mockRunner,
        assigns: true,
      });
    });

    describe('canAssignRunners is false', () => {
      it('does not render assign button', () => {
        createComponent({ runner: mockRunner, provide: { canAssignRunners: false } });

        expect(findRunnerToggleAssignButton('runner-assign-button').exists()).toBe(false);
      });
    });

    it('emits an error event', () => {
      findRunnerTab('other-project-runners-tab').vm.$emit('error', error);

      expect(wrapper.emitted().error[0]).toEqual([error]);
    });

    describe('when runner is assigned', () => {
      beforeEach(async () => {
        findRunnerToggleAssignButton('runner-unassign-button').vm.$emit('done', {
          message: 'Runner assigned.',
        });
        await nextTick();
      });

      it('refreshes project tabs after assigning', () => {
        expect(mockRefresh).toHaveBeenCalledTimes(2);
        expect(mockRefresh).toHaveBeenCalledWith('Assigned project runners');
        expect(mockRefresh).toHaveBeenCalledWith('Other available project runners');
      });

      it('shows confirmation toast', () => {
        expect(mockShowToast).toHaveBeenCalledWith('Runner assigned.');
      });
    });
  });

  describe('Group tab', () => {
    it('renders the tab content', () => {
      expect(findRunnerTab('group-runners-tab').props()).toMatchObject({
        title: 'Group',
        runnerType: GROUP_TYPE,
        projectFullPath: 'group/project',
      });
      expect(findRunnerTab('group-runners-tab').text()).toContain(
        'These runners are shared across projects in this group.',
      );
      expect(findRunnerTab('group-runners-tab').findComponent(GroupRunnersToggle).exists()).toBe(
        true,
      );

      const emptyState =
        findRunnerTab('group-runners-tab').findComponent(GroupRunnersTabEmptyState);
      expect(emptyState.exists()).toBe(true);
      expect(emptyState.props('groupRunnersEnabled')).toBe(true);
    });

    describe('when isGroupRunnersEnabled is false', () => {
      it('renders GroupRunnersTabEmptyState with correct groupRunnersEnabled prop value', () => {
        createComponent({ runner: mockRunner, provide: { isGroupRunnersEnabled: false } });

        const emptyState =
          findRunnerTab('group-runners-tab').findComponent(GroupRunnersTabEmptyState);
        expect(emptyState.props('groupRunnersEnabled')).toBe(false);
      });
    });

    describe('canToggleGroupRunners is false', () => {
      it('does not render toggle', () => {
        createComponent({ runner: mockRunner, provide: { canToggleGroupRunners: false } });

        expect(findRunnerTab('group-runners-tab').findComponent(GroupRunnersToggle).exists()).toBe(
          false,
        );
      });
    });

    it('updates list and empty state on toggle', async () => {
      findRunnerTab('group-runners-tab')
        .findComponent(GroupRunnersToggle)
        .vm.$emit('change', false);
      await nextTick();

      expect(mockRefresh).toHaveBeenCalledTimes(1);
      expect(mockRefresh).toHaveBeenCalledWith('Group');
      expect(
        findRunnerTab('group-runners-tab')
          .findComponent(GroupRunnersTabEmptyState)
          .props('groupRunnersEnabled'),
      ).toBe(false);
    });

    it('emits an error event from toggle', () => {
      findRunnerTab('group-runners-tab').findComponent(GroupRunnersToggle).vm.$emit('error', error);

      expect(wrapper.emitted().error[0]).toEqual([error]);
    });

    it('emits an error event', () => {
      findRunnerTab('group-runners-tab').vm.$emit('error', error);

      expect(wrapper.emitted().error[0]).toEqual([error]);
    });
  });

  describe('Instance tab', () => {
    it('renders the tab content', () => {
      expect(findRunnerTab('instance-runners-tab').props()).toMatchObject({
        title: 'Instance',
        runnerType: INSTANCE_TYPE,
        projectFullPath: 'group/project',
      });
      expect(
        findRunnerTab('instance-runners-tab').findComponent(InstanceRunnersTabEmptyState).exists(),
      ).toBe(true);
    });

    it('shows instance runners toggle', () => {
      expect(
        findRunnerTab('instance-runners-tab').findComponent(InstanceRunnersToggle).props(),
      ).toEqual({
        groupName: 'My group',
        groupSettingsPath: 'group/project/-/settings/ci_cd#runners-settings',
        isDisabledAndUnoverridable: false,
        isEnabled: true,
        updatePath: 'group/project/-/runners/toggle_shared_runners',
      });
    });

    describe('canToggleInstanceRunners is false', () => {
      it('does not render toggle', () => {
        createComponent({ runner: mockRunner, provide: { canToggleInstanceRunners: false } });

        expect(
          findRunnerTab('instance-runners-tab').findComponent(InstanceRunnersToggle).exists(),
        ).toBe(false);
      });
    });

    it('updates list and empty state on toggle', async () => {
      findRunnerTab('instance-runners-tab')
        .findComponent(InstanceRunnersToggle)
        .vm.$emit('change', false);
      await nextTick();

      expect(mockRefresh).toHaveBeenCalledTimes(1);
      expect(mockRefresh).toHaveBeenCalledWith('Instance');
      expect(
        findRunnerTab('instance-runners-tab')
          .findComponent(InstanceRunnersToggle)
          .props('isEnabled'),
      ).toBe(false);
    });

    it('emits an error event', () => {
      findRunnerTab('instance-runners-tab').vm.$emit('error', error);

      expect(wrapper.emitted().error[0]).toEqual([error]);
    });
  });
});
