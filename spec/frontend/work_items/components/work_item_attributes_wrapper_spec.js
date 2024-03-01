import { nextTick } from 'vue';
import { shallowMount } from '@vue/test-utils';
import Participants from '~/sidebar/components/participants/participants.vue';
import WorkItemAssigneesWithEdit from '~/work_items/components/work_item_assignees_with_edit.vue';
import WorkItemDueDateInline from '~/work_items/components/work_item_due_date_inline.vue';
import WorkItemDueDateWithEdit from '~/work_items/components/work_item_due_date_with_edit.vue';
import WorkItemLabelsInline from '~/work_items/components/work_item_labels_inline.vue';
import WorkItemLabelsWithEdit from '~/work_items/components/work_item_labels_with_edit.vue';
import WorkItemMilestoneInline from '~/work_items/components/work_item_milestone_inline.vue';
import WorkItemMilestoneWithEdit from '~/work_items/components/work_item_milestone_with_edit.vue';
import WorkItemParentInline from '~/work_items/components/work_item_parent_inline.vue';
import WorkItemParent from '~/work_items/components/work_item_parent_with_edit.vue';
import WorkItemTimeTracking from '~/work_items/components/work_item_time_tracking.vue';
import waitForPromises from 'helpers/wait_for_promises';
import WorkItemAttributesWrapper from '~/work_items/components/work_item_attributes_wrapper.vue';
import {
  workItemResponseFactory,
  taskType,
  objectiveType,
  keyResultType,
  issueType,
  epicType,
} from '../mock_data';

describe('WorkItemAttributesWrapper component', () => {
  let wrapper;

  const workItemQueryResponse = workItemResponseFactory({ canUpdate: true, canDelete: true });

  const findWorkItemAssignees = () => wrapper.findComponent(WorkItemAssigneesWithEdit);
  const findWorkItemDueDate = () => wrapper.findComponent(WorkItemDueDateWithEdit);
  const findWorkItemDueDateInline = () => wrapper.findComponent(WorkItemDueDateInline);
  const findWorkItemLabelsInline = () => wrapper.findComponent(WorkItemLabelsInline);
  const findWorkItemLabels = () => wrapper.findComponent(WorkItemLabelsWithEdit);
  const findWorkItemMilestone = () => wrapper.findComponent(WorkItemMilestoneWithEdit);
  const findWorkItemMilestoneInline = () => wrapper.findComponent(WorkItemMilestoneInline);
  const findWorkItemParentInline = () => wrapper.findComponent(WorkItemParentInline);
  const findWorkItemParent = () => wrapper.findComponent(WorkItemParent);
  const findWorkItemTimeTracking = () => wrapper.findComponent(WorkItemTimeTracking);
  const findWorkItemParticipants = () => wrapper.findComponent(Participants);

  const createComponent = ({
    workItem = workItemQueryResponse.data.workItem,
    workItemsBeta = true,
  } = {}) => {
    wrapper = shallowMount(WorkItemAttributesWrapper, {
      propsData: {
        fullPath: 'group/project',
        workItem,
      },
      provide: {
        hasIssueWeightsFeature: true,
        hasIterationsFeature: true,
        hasOkrsFeature: true,
        hasIssuableHealthStatusFeature: true,
        projectNamespace: 'namespace',
        glFeatures: {
          workItemsBeta,
        },
      },
      stubs: {
        WorkItemWeight: true,
        WorkItemIteration: true,
        WorkItemHealthStatus: true,
      },
    });
  };

  describe('assignees widget', () => {
    it('renders assignees component when widget is returned from the API', () => {
      createComponent();

      expect(findWorkItemAssignees().exists()).toBe(true);
    });

    it('does not render assignees component when widget is not returned from the API', () => {
      createComponent({
        workItem: workItemResponseFactory({ assigneesWidgetPresent: false }).data.workItem,
      });

      expect(findWorkItemAssignees().exists()).toBe(false);
    });
  });

  describe('labels widget', () => {
    it.each`
      description                                               | labelsWidgetPresent | exists
      ${'renders when widget is returned from API'}             | ${true}             | ${true}
      ${'does not render when widget is not returned from API'} | ${false}            | ${false}
    `('$description', ({ labelsWidgetPresent, exists }) => {
      const response = workItemResponseFactory({ labelsWidgetPresent });
      createComponent({ workItem: response.data.workItem });

      expect(findWorkItemLabels().exists()).toBe(exists);
    });

    it.each`
      description                                                   | labelsWidgetInlinePresent | labelsWidgetWithEditPresent | workItemsBetaFlagEnabled
      ${'renders WorkItemLabels when workItemsBeta enabled'}        | ${false}                  | ${true}                     | ${true}
      ${'renders WorkItemLabelsInline when workItemsBeta disabled'} | ${true}                   | ${false}                    | ${false}
    `(
      '$description',
      async ({
        labelsWidgetInlinePresent,
        labelsWidgetWithEditPresent,
        workItemsBetaFlagEnabled,
      }) => {
        createComponent({ workItemsBeta: workItemsBetaFlagEnabled });

        await waitForPromises();

        expect(findWorkItemLabels().exists()).toBe(labelsWidgetWithEditPresent);
        expect(findWorkItemLabelsInline().exists()).toBe(labelsWidgetInlinePresent);
      },
    );
  });

  describe('dates widget', () => {
    describe.each`
      description                               | datesWidgetPresent | exists
      ${'when widget is returned from API'}     | ${true}            | ${true}
      ${'when widget is not returned from API'} | ${false}           | ${false}
    `('$description', ({ datesWidgetPresent, exists }) => {
      it(`${datesWidgetPresent ? 'renders' : 'does not render'} due date component`, () => {
        const response = workItemResponseFactory({ datesWidgetPresent });
        createComponent({ workItem: response.data.workItem });

        expect(findWorkItemDueDate().exists()).toBe(exists);
      });
    });

    it.each`
      description                                                     | dueDateWidgetInlinePresent | dueDateWidgetWithEditPresent | workItemsBetaFlagEnabled
      ${'renders WorkItemDueDateWithEdit when workItemsBeta enabled'} | ${false}                   | ${true}                      | ${true}
      ${'renders WorkItemDueDateInline when workItemsBeta disabled'}  | ${true}                    | ${false}                     | ${false}
    `(
      '$description',
      async ({
        dueDateWidgetInlinePresent,
        dueDateWidgetWithEditPresent,
        workItemsBetaFlagEnabled,
      }) => {
        createComponent({ workItemsBeta: workItemsBetaFlagEnabled });

        await waitForPromises();

        expect(findWorkItemDueDate().exists()).toBe(dueDateWidgetWithEditPresent);
        expect(findWorkItemDueDateInline().exists()).toBe(dueDateWidgetInlinePresent);
      },
    );
  });

  describe('milestone widget', () => {
    it.each`
      description                                               | milestoneWidgetPresent | exists
      ${'renders when widget is returned from API'}             | ${true}                | ${true}
      ${'does not render when widget is not returned from API'} | ${false}               | ${false}
    `('$description', ({ milestoneWidgetPresent, exists }) => {
      const response = workItemResponseFactory({ milestoneWidgetPresent });
      createComponent({ workItem: response.data.workItem });

      expect(findWorkItemMilestone().exists()).toBe(exists);
    });

    it.each`
      description                                                      | milestoneWidgetInlinePresent | milestoneWidgetWithEditPresent | workItemsBetaFlagEnabled
      ${'renders WorkItemMilestone when workItemsBeta enabled'}        | ${false}                     | ${true}                        | ${true}
      ${'renders WorkItemMilestoneInline when workItemsBeta disabled'} | ${true}                      | ${false}                       | ${false}
    `(
      '$description',
      async ({
        milestoneWidgetInlinePresent,
        milestoneWidgetWithEditPresent,
        workItemsBetaFlagEnabled,
      }) => {
        createComponent({ workItemsBeta: workItemsBetaFlagEnabled });

        await waitForPromises();

        expect(findWorkItemMilestone().exists()).toBe(milestoneWidgetWithEditPresent);
        expect(findWorkItemMilestoneInline().exists()).toBe(milestoneWidgetInlinePresent);
      },
    );
  });

  describe('parent widget', () => {
    describe.each`
      description                            | workItemType     | exists
      ${'when work item type is task'}       | ${taskType}      | ${true}
      ${'when work item type is objective'}  | ${objectiveType} | ${true}
      ${'when work item type is key result'} | ${keyResultType} | ${true}
      ${'when work item type is issue'}      | ${issueType}     | ${true}
      ${'when work item type is epic'}       | ${epicType}      | ${true}
    `('$description', ({ workItemType, exists }) => {
      it(`${exists ? 'renders' : 'does not render'} parent component`, async () => {
        const response = workItemResponseFactory({ workItemType });
        createComponent({ workItem: response.data.workItem });

        await waitForPromises();

        expect(findWorkItemParent().exists()).toBe(exists);
      });
    });

    it('renders WorkItemParent when workItemsBeta enabled', async () => {
      createComponent();

      await waitForPromises();

      expect(findWorkItemParent().exists()).toBe(true);
      expect(findWorkItemParentInline().exists()).toBe(false);
    });

    it('renders WorkItemParentInline when workItemsBeta disabled', async () => {
      createComponent({ workItemsBeta: false });

      await waitForPromises();

      expect(findWorkItemParent().exists()).toBe(false);
      expect(findWorkItemParentInline().exists()).toBe(true);
    });

    it('emits an error event to the wrapper', async () => {
      const response = workItemResponseFactory({ parentWidgetPresent: true });
      createComponent({ workItem: response.data.workItem });
      const updateError = 'Failed to update';

      await waitForPromises();

      findWorkItemParent().vm.$emit('error', updateError);
      await nextTick();

      expect(wrapper.emitted('error')).toEqual([[updateError]]);
    });
  });

  describe('time tracking widget', () => {
    it.each`
      description                                               | timeTrackingWidgetPresent | exists
      ${'renders when widget is returned from API'}             | ${true}                   | ${true}
      ${'does not render when widget is not returned from API'} | ${false}                  | ${false}
    `('$description', ({ timeTrackingWidgetPresent, exists }) => {
      const response = workItemResponseFactory({ timeTrackingWidgetPresent });
      createComponent({ workItem: response.data.workItem });

      expect(findWorkItemTimeTracking().exists()).toBe(exists);
    });
  });

  describe('participants widget', () => {
    it.each`
      description                                               | participantsWidgetPresent | exists
      ${'renders when widget is returned from API'}             | ${true}                   | ${true}
      ${'does not render when widget is not returned from API'} | ${false}                  | ${false}
    `('$description', ({ participantsWidgetPresent, exists }) => {
      const response = workItemResponseFactory({ participantsWidgetPresent });
      createComponent({ workItem: response.data.workItem });

      expect(findWorkItemParticipants().exists()).toBe(exists);
    });
  });
});
