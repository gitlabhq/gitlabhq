import { GlForm } from '@gitlab/ui';
import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import createMockApollo from 'helpers/mock_apollo_helper';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { createAlert } from '~/alert';
import WorkItemBulkEditAssignee from '~/work_items/components/work_item_bulk_edit/work_item_bulk_edit_assignee.vue';
import WorkItemBulkEditLabels from '~/work_items/components/work_item_bulk_edit/work_item_bulk_edit_labels.vue';
import WorkItemBulkEditMilestone from '~/work_items/components/work_item_bulk_edit/work_item_bulk_edit_milestone.vue';
import WorkItemBulkEditParent from '~/work_items/components/work_item_bulk_edit/work_item_bulk_edit_parent.vue';
import WorkItemBulkEditSidebar from '~/work_items/components/work_item_bulk_edit/work_item_bulk_edit_sidebar.vue';
import WorkItemBulkMove from '~/work_items/components/work_item_bulk_edit/work_item_bulk_move.vue';
import workItemBulkUpdateMutation from '~/work_items/graphql/list/work_item_bulk_update.mutation.graphql';
import getAvailableBulkEditWidgets from '~/work_items/graphql/list/get_available_bulk_edit_widgets.query.graphql';
import {
  BULK_EDIT_NO_VALUE,
  WIDGET_TYPE_ASSIGNEES,
  WIDGET_TYPE_HEALTH_STATUS,
  WIDGET_TYPE_HIERARCHY,
  WIDGET_TYPE_LABELS,
  WIDGET_TYPE_MILESTONE,
} from '~/work_items/constants';
import { availableBulkEditWidgetsQueryResponse } from '../../mock_data';

jest.mock('~/alert');

Vue.use(VueApollo);

const availableWidgetsWithout = (widgetToExclude) => {
  const widgetNames = availableBulkEditWidgetsQueryResponse.data.namespace.workItemsWidgets.filter(
    (name) => name !== widgetToExclude,
  );
  return {
    data: {
      namespace: {
        ...availableBulkEditWidgetsQueryResponse.data.namespace,
        workItemsWidgets: widgetNames,
      },
    },
  };
};

describe('WorkItemBulkEditSidebar component', () => {
  let wrapper;

  const checkedItems = [
    {
      id: 'gid://gitlab/WorkItem/11',
      title: 'Work Item 11',
      workItemType: { id: 'gid://gitlab/WorkItems::Type/8' },
    },
    {
      id: 'gid://gitlab/WorkItem/22',
      title: 'Work Item 22',
      workItemType: { id: 'gid://gitlab/WorkItems::Type/5' },
    },
  ];

  const workItemBulkUpdateHandler = jest
    .fn()
    .mockResolvedValue({ data: { workItemBulkUpdate: { updatedWorkItemCount: 1 } } });
  const defaultAvailableWidgetsHandler = jest
    .fn()
    .mockResolvedValue(availableBulkEditWidgetsQueryResponse);

  const createComponent = ({
    provide = {},
    props = {},
    mutationHandler = workItemBulkUpdateHandler,
    availableWidgetsHandler = defaultAvailableWidgetsHandler,
    items = checkedItems,
  } = {}) => {
    wrapper = shallowMountExtended(WorkItemBulkEditSidebar, {
      apolloProvider: createMockApollo([
        [workItemBulkUpdateMutation, mutationHandler],
        [getAvailableBulkEditWidgets, availableWidgetsHandler],
      ]),
      provide: {
        hasIssuableHealthStatusFeature: false,
        hasIterationsFeature: false,
        hasStatusFeature: false,
        ...provide,
      },
      propsData: {
        checkedItems: items,
        fullPath: 'group/project',
        isGroup: false,
        ...props,
      },
    });
  };

  const findForm = () => wrapper.findComponent(GlForm);
  const findStateComponent = () => wrapper.findComponentByTestId('bulk-edit-state');
  const findAssigneeComponent = () => wrapper.findComponent(WorkItemBulkEditAssignee);
  const findAddLabelsComponent = () => wrapper.findAllComponents(WorkItemBulkEditLabels).at(0);
  const findRemoveLabelsComponent = () => wrapper.findAllComponents(WorkItemBulkEditLabels).at(1);
  const findHealthStatusComponent = () => wrapper.findComponentByTestId('bulk-edit-health-status');
  const findSubscriptionComponent = () => wrapper.findComponentByTestId('bulk-edit-subscription');
  const findConfidentialityComponent = () =>
    wrapper.findComponentByTestId('bulk-edit-confidentiality');
  const findMilestoneComponent = () => wrapper.findComponent(WorkItemBulkEditMilestone);
  const findParentComponent = () => wrapper.findComponent(WorkItemBulkEditParent);
  const findBulkMoveComponent = () => wrapper.findComponent(WorkItemBulkMove);

  describe('form', () => {
    it('renders', () => {
      createComponent();

      expect(findForm().attributes('id')).toBe('work-item-list-bulk-edit');
    });

    it('calls mutation to bulk edit with project fullPath', async () => {
      const addLabelIds = ['gid://gitlab/Label/1'];
      const removeLabelIds = ['gid://gitlab/Label/2'];
      createComponent({
        provide: {
          hasIssuableHealthStatusFeature: true,
        },
        props: { isEpicsList: false, fullPath: 'group/project' },
      });
      await waitForPromises();

      findAssigneeComponent().vm.$emit('input', 'gid://gitlab/User/5');
      findAddLabelsComponent().vm.$emit('select', addLabelIds);
      findRemoveLabelsComponent().vm.$emit('select', removeLabelIds);
      findHealthStatusComponent().vm.$emit('input', 'on_track');
      findConfidentialityComponent().vm.$emit('input', 'true');
      findMilestoneComponent().vm.$emit('input', 'gid://gitlab/Milestone/30');
      findSubscriptionComponent().vm.$emit('input', 'unsubscribe');
      findStateComponent().vm.$emit('input', 'reopen');
      findParentComponent().vm.$emit('input', 'gid://gitlab/WorkItem/101');
      findForm().vm.$emit('submit', { preventDefault: () => {} });

      expect(workItemBulkUpdateHandler).toHaveBeenCalledWith({
        input: {
          fullPath: 'group/project',
          ids: ['gid://gitlab/WorkItem/11', 'gid://gitlab/WorkItem/22'],
          labelsWidget: {
            addLabelIds,
            removeLabelIds,
          },
          assigneesWidget: {
            assigneeIds: ['gid://gitlab/User/5'],
          },
          confidential: true,
          healthStatusWidget: {
            healthStatus: 'onTrack',
          },
          milestoneWidget: {
            milestoneId: 'gid://gitlab/Milestone/30',
          },
          subscriptionEvent: 'UNSUBSCRIBE',
          stateEvent: 'REOPEN',
          hierarchyWidget: {
            parentId: 'gid://gitlab/WorkItem/101',
          },
        },
      });
      expect(findAddLabelsComponent().props('selectedLabelsIds')).toEqual([]);
      expect(findRemoveLabelsComponent().props('selectedLabelsIds')).toEqual([]);
    });

    it('calls mutation with null values to bulk edit when "No value" is chosen', async () => {
      createComponent({
        provide: {
          hasIssuableHealthStatusFeature: true,
        },
        props: { isEpicsList: false, fullPath: 'group/project' },
      });
      await waitForPromises();

      findAssigneeComponent().vm.$emit('input', BULK_EDIT_NO_VALUE);
      findHealthStatusComponent().vm.$emit('input', BULK_EDIT_NO_VALUE);
      findMilestoneComponent().vm.$emit('input', BULK_EDIT_NO_VALUE);
      findParentComponent().vm.$emit('input', BULK_EDIT_NO_VALUE);
      findForm().vm.$emit('submit', { preventDefault: () => {} });

      expect(workItemBulkUpdateHandler).toHaveBeenCalledWith({
        input: {
          fullPath: 'group/project',
          ids: ['gid://gitlab/WorkItem/11', 'gid://gitlab/WorkItem/22'],
          assigneesWidget: {
            assigneeIds: [null],
          },
          healthStatusWidget: {
            healthStatus: null,
          },
          milestoneWidget: {
            milestoneId: null,
          },
          hierarchyWidget: {
            parentId: null,
          },
        },
      });
    });

    it('calls mutation with namespace fullPath', async () => {
      createComponent({
        props: { isEpicsList: false, fullPath: 'group/subgroup/project' },
      });
      await waitForPromises();

      findForm().vm.$emit('submit', { preventDefault: () => {} });

      expect(workItemBulkUpdateHandler).toHaveBeenCalledWith({
        input: {
          fullPath: 'group/subgroup/project',
          ids: ['gid://gitlab/WorkItem/11', 'gid://gitlab/WorkItem/22'],
        },
      });
    });

    it('renders error when there is a mutation error', async () => {
      createComponent({
        props: { isEpicsList: true },
        mutationHandler: jest.fn().mockRejectedValue(new Error('oh no')),
      });

      findForm().vm.$emit('submit', { preventDefault: () => {} });
      await waitForPromises();

      expect(createAlert).toHaveBeenCalledWith({
        captureError: true,
        error: new Error('oh no'),
        message: 'Something went wrong while bulk editing.',
      });
    });
  });

  describe('widget visibility', () => {
    it('shows the correct widgets', () => {
      createComponent();

      // visible
      expect(findStateComponent().exists()).toBe(true);
      expect(findAssigneeComponent().exists()).toBe(true);
      expect(findAddLabelsComponent().exists()).toBe(true);
      expect(findRemoveLabelsComponent().exists()).toBe(true);
      expect(findSubscriptionComponent().exists()).toBe(true);
      expect(findConfidentialityComponent().exists()).toBe(true);
      expect(findMilestoneComponent().exists()).toBe(true);
      expect(findParentComponent().exists()).toBe(true);
      expect(findBulkMoveComponent().exists()).toBe(true);
    });
  });

  describe('getAvailableBulkEditWidgets query', () => {
    beforeEach(() => {
      createComponent();
    });

    it('is called when mounted', () => {
      expect(defaultAvailableWidgetsHandler).toHaveBeenCalled();
    });

    it('is called when checkedItems is updated and there is a new work item type', async () => {
      await wrapper.setProps({
        checkedItems: [
          ...checkedItems,
          {
            id: 'gid://gitlab/WorkItem/14',
            title: 'Work Item 14',
            workItemType: { id: 'gid://gitlab/WorkItems::Type/9' },
          },
        ],
      });

      await nextTick();
      await waitForPromises();

      // once on initial mount, once when checked items change
      expect(defaultAvailableWidgetsHandler).toHaveBeenCalledTimes(2);
    });
  });

  describe('"State" component', () => {
    it.each([true, false])('renders depending on isEpicsList prop', (isEpicsList) => {
      createComponent({ props: { isEpicsList } });

      expect(findStateComponent().exists()).toBe(!isEpicsList);
    });

    it('updates state when "State" component emits "input" event', async () => {
      createComponent();

      findStateComponent().vm.$emit('input', 'reopen');
      await nextTick();

      expect(findStateComponent().props('value')).toBe('reopen');
    });
  });

  describe('"Assignee" component', () => {
    it('updates assignee when "Assignee" component emits "input" event', async () => {
      createComponent();

      findAssigneeComponent().vm.$emit('input', 'gid://gitlab/User/5');
      await nextTick();

      expect(findAssigneeComponent().props('value')).toBe('gid://gitlab/User/5');
    });

    it('enables "Assignee" component when "Assignees" widget is available', async () => {
      createComponent({
        props: { isEpicsList: false },
      });

      await nextTick();
      await waitForPromises();

      expect(findAssigneeComponent().props('disabled')).toBe(false);
    });

    it('disables "Assignee" component when "Assignees" widget is unavailable', async () => {
      createComponent({
        props: { isEpicsList: false },
        availableWidgetsHandler: jest
          .fn()
          .mockResolvedValue(availableWidgetsWithout(WIDGET_TYPE_ASSIGNEES)),
      });

      await nextTick();
      await waitForPromises();

      expect(findAssigneeComponent().props('disabled')).toBe(true);
    });
  });

  describe('"Add labels" component', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders', () => {
      expect(findAddLabelsComponent().props('formLabel')).toBe('Add labels');
    });

    it('updates labels to add when "Add labels" component emits "select" event', async () => {
      const labelIds = ['gid://gitlab/Label/1', 'gid://gitlab/Label/2'];

      findAddLabelsComponent().vm.$emit('select', labelIds);
      await nextTick();

      expect(findAddLabelsComponent().props('selectedLabelsIds')).toEqual(labelIds);
    });

    it('enables "Add labels" component when "Labels" widget is available', async () => {
      createComponent({
        props: { isEpicsList: false },
      });

      await nextTick();
      await waitForPromises();

      expect(findAddLabelsComponent().props('disabled')).toBe(false);
    });

    it('disables "Add labels" component when "Labels" widget is unavailable', async () => {
      createComponent({
        props: { isEpicsList: false },
        availableWidgetsHandler: jest
          .fn()
          .mockResolvedValue(availableWidgetsWithout(WIDGET_TYPE_LABELS)),
      });

      await nextTick();
      await waitForPromises();

      expect(findAddLabelsComponent().props('disabled')).toBe(true);
    });
  });

  describe('"Remove labels" component', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders', () => {
      expect(findRemoveLabelsComponent().props('formLabel')).toBe('Remove labels');
    });

    it('updates labels to remove when "Remove labels" component emits "select" event', async () => {
      const labelIds = ['gid://gitlab/Label/1', 'gid://gitlab/Label/2'];

      findRemoveLabelsComponent().vm.$emit('select', labelIds);
      await nextTick();

      expect(findRemoveLabelsComponent().props('selectedLabelsIds')).toEqual(labelIds);
    });

    it('enables "Remove labels" component when "Labels" widget is available', async () => {
      createComponent({
        props: { isEpicsList: false },
      });

      await nextTick();
      await waitForPromises();

      expect(findRemoveLabelsComponent().props('disabled')).toBe(false);
    });

    it('disables "Remove labels" component when "Labels" widget is unavailable', async () => {
      createComponent({
        props: { isEpicsList: false },
        availableWidgetsHandler: jest
          .fn()
          .mockResolvedValue(availableWidgetsWithout(WIDGET_TYPE_LABELS)),
      });

      await nextTick();
      await waitForPromises();

      expect(findRemoveLabelsComponent().props('disabled')).toBe(true);
    });
  });

  describe('"Health status" component', () => {
    it.each([true, false])(
      'renders depending on hasIssuableHealthStatusFeature feature',
      (hasIssuableHealthStatusFeature) => {
        createComponent({
          provide: {
            hasIssuableHealthStatusFeature,
          },
        });

        expect(findHealthStatusComponent().exists()).toBe(hasIssuableHealthStatusFeature);
      },
    );

    it('updates health status when "Health status" component emits "input" event', async () => {
      createComponent({ provide: { hasIssuableHealthStatusFeature: true } });

      findHealthStatusComponent().vm.$emit('input', 'needs_attention');
      await nextTick();

      expect(findHealthStatusComponent().props('value')).toBe('needs_attention');
    });

    it('enables "Health status" component when "Health status" widget is available', async () => {
      createComponent({
        provide: {
          hasIssuableHealthStatusFeature: true,
        },
        props: { isEpicsList: false },
      });

      await nextTick();
      await waitForPromises();

      expect(findHealthStatusComponent().props('disabled')).toBe(false);
    });

    it('disables "Health status" component when "Health status" widget is unavailable', async () => {
      createComponent({
        provide: {
          hasIssuableHealthStatusFeature: true,
        },
        props: { isEpicsList: false },
        availableWidgetsHandler: jest
          .fn()
          .mockResolvedValue(availableWidgetsWithout(WIDGET_TYPE_HEALTH_STATUS)),
      });

      await nextTick();
      await waitForPromises();

      expect(findHealthStatusComponent().props('disabled')).toBe(true);
    });
  });

  describe('"Subscription" component', () => {
    it('updates subscription when "Subscription" component emits "input" event', async () => {
      createComponent();

      findSubscriptionComponent().vm.$emit('input', 'unsubscribe');
      await nextTick();

      expect(findSubscriptionComponent().props('value')).toBe('unsubscribe');
    });
  });

  describe('"Confidentiality" component', () => {
    it('updates confidentiality when "Confidentiality" component emits "input" event', async () => {
      createComponent();

      findConfidentialityComponent().vm.$emit('input', 'false');
      await nextTick();

      expect(findConfidentialityComponent().props('value')).toBe('false');
    });
  });

  describe('"Milestone" component', () => {
    it('updates milestone when "Milestone" component emits "input" event', async () => {
      createComponent({
        props: { isEpicsList: false },
      });

      findMilestoneComponent().vm.$emit('input', 'gid://gitlab/Milestone/30');
      await nextTick();

      expect(findMilestoneComponent().props('value')).toBe('gid://gitlab/Milestone/30');
    });

    it('enables "Milestone" component when "Milestone" widget is available', async () => {
      createComponent({
        props: { isEpicsList: false },
      });

      await nextTick();
      await waitForPromises();

      expect(findMilestoneComponent().props('disabled')).toBe(false);
    });

    it('disables "Milestone" component when "Milestone" widget is unavailable', async () => {
      createComponent({
        props: { isEpicsList: false },
        availableWidgetsHandler: jest
          .fn()
          .mockResolvedValue(availableWidgetsWithout(WIDGET_TYPE_MILESTONE)),
      });

      await nextTick();
      await waitForPromises();

      expect(findMilestoneComponent().props('disabled')).toBe(true);
    });
  });

  describe('"Parent" component', () => {
    it('updates parent when "Parent" component emits "input" event', async () => {
      createComponent({
        props: { isEpicsList: false },
      });

      findParentComponent().vm.$emit('input', 'gid://gitlab/WorkItem/30');
      await nextTick();

      expect(findParentComponent().props('value')).toBe('gid://gitlab/WorkItem/30');
    });

    it('enables "Parent" component when "Hierarchy" widget is available', async () => {
      createComponent({
        props: { isEpicsList: false },
      });

      await nextTick();
      await waitForPromises();

      expect(findParentComponent().props('disabled')).toBe(false);
    });

    it('disables "Parent" component when "Hierarchy" widget is unavailable', async () => {
      createComponent({
        props: { isEpicsList: false },
        availableWidgetsHandler: jest
          .fn()
          .mockResolvedValue(availableWidgetsWithout(WIDGET_TYPE_HIERARCHY)),
      });

      await nextTick();
      await waitForPromises();

      expect(findParentComponent().props('disabled')).toBe(true);
    });
  });

  describe('bulk move', () => {
    const mountForBulkMove = (items = checkedItems) => {
      createComponent({
        items,
        props: { isEpicsList: false },
      });
    };

    it('renders bulk move when available', () => {
      mountForBulkMove();

      expect(findBulkMoveComponent().exists()).toBe(true);
    });

    it('passes checked items and fullPath as a prop', () => {
      mountForBulkMove();

      expect(findBulkMoveComponent().props('checkedItems')).toBe(checkedItems);
      expect(findBulkMoveComponent().props('fullPath')).toBe('group/project');
    });

    it('disables bulk move when there are no checked items', () => {
      mountForBulkMove([]);

      expect(findBulkMoveComponent().props('disabled')).toBe(true);
    });

    it('disables bulk move when there are other bulk edit properties set', async () => {
      mountForBulkMove();

      expect(findBulkMoveComponent().props('disabled')).toBe(false);

      findConfidentialityComponent().vm.$emit('input', 'true');

      await nextTick();

      expect(findBulkMoveComponent().props('disabled')).toBe(true);
    });

    it('emits "start" when bulk move emits "moveStart"', () => {
      mountForBulkMove();

      findBulkMoveComponent().vm.$emit('moveStart');

      expect(wrapper.emitted('start')).toHaveLength(1);
    });

    it('emits "success" when bulk move emits "moveSuccess"', () => {
      mountForBulkMove();

      findBulkMoveComponent().vm.$emit('moveSuccess', { toastMessage: 'hello!' });

      const events = wrapper.emitted('success');

      expect(events).toHaveLength(1);
      expect(events[0][0]).toEqual({ refetchCounts: true, toastMessage: 'hello!' });
    });

    it('emits "finish" when bulk move emits "moveFinish"', () => {
      mountForBulkMove();

      findBulkMoveComponent().vm.$emit('moveFinish');

      expect(wrapper.emitted('finish')).toHaveLength(1);
    });
  });
});
