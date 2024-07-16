import { nextTick } from 'vue';
import { shallowMount } from '@vue/test-utils';
import Participants from '~/sidebar/components/participants/participants.vue';
import WorkItemAssignees from '~/work_items/components/work_item_assignees.vue';
import WorkItemDueDate from '~/work_items/components/work_item_due_date.vue';
import WorkItemLabels from '~/work_items/components/work_item_labels.vue';
import WorkItemMilestone from '~/work_items/components/work_item_milestone.vue';
import WorkItemParent from '~/work_items/components/work_item_parent.vue';
import WorkItemTimeTracking from '~/work_items/components/work_item_time_tracking.vue';
import WorkItemDevelopment from '~/work_items/components/work_item_development/work_item_development.vue';
import waitForPromises from 'helpers/wait_for_promises';
import WorkItemAttributesWrapper from '~/work_items/components/work_item_attributes_wrapper.vue';
import { workItemResponseFactory } from '../mock_data';

describe('WorkItemAttributesWrapper component', () => {
  let wrapper;

  const workItemQueryResponse = workItemResponseFactory({ canUpdate: true, canDelete: true });

  const findWorkItemAssignees = () => wrapper.findComponent(WorkItemAssignees);
  const findWorkItemDueDate = () => wrapper.findComponent(WorkItemDueDate);
  const findWorkItemLabels = () => wrapper.findComponent(WorkItemLabels);
  const findWorkItemMilestone = () => wrapper.findComponent(WorkItemMilestone);
  const findWorkItemParent = () => wrapper.findComponent(WorkItemParent);
  const findWorkItemTimeTracking = () => wrapper.findComponent(WorkItemTimeTracking);
  const findWorkItemParticipants = () => wrapper.findComponent(Participants);
  const findWorkItemDevelopment = () => wrapper.findComponent(WorkItemDevelopment);

  const createComponent = ({
    workItem = workItemQueryResponse.data.workItem,
    workItemsAlpha = false,
    groupPath = '',
  } = {}) => {
    wrapper = shallowMount(WorkItemAttributesWrapper, {
      propsData: {
        fullPath: 'group/project',
        workItem,
        groupPath,
      },
      provide: {
        hasIssueWeightsFeature: true,
        hasIterationsFeature: true,
        hasOkrsFeature: true,
        hasIssuableHealthStatusFeature: true,
        projectNamespace: 'namespace',
        hasSubepicsFeature: true,
        glFeatures: {
          workItemsAlpha,
        },
      },
      stubs: {
        WorkItemWeight: true,
        WorkItemIteration: true,
        WorkItemHealthStatus: true,
        WorkItemParent: true,
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

    it('renders WorkItemLabels', async () => {
      createComponent();

      await waitForPromises();

      expect(findWorkItemLabels().exists()).toBe(true);
    });
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

    it('renders WorkItemDueDate', async () => {
      createComponent();

      await waitForPromises();

      expect(findWorkItemDueDate().exists()).toBe(true);
    });
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

    it('renders WorkItemMilestone', async () => {
      createComponent();

      await waitForPromises();

      expect(findWorkItemMilestone().exists()).toBe(true);
    });
  });

  describe('parent widget', () => {
    it(`renders parent component with proper data`, async () => {
      const response = workItemResponseFactory();
      createComponent({ workItem: response.data.workItem });

      await waitForPromises();

      expect(findWorkItemParent().exists()).toBe(true);
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

  describe('development widget', () => {
    describe('when `workItesMvc2` FF is off', () => {
      it.each`
        description                                               | developmentWidgetPresent | exists
        ${'does not render when widget is returned from API'}     | ${true}                  | ${false}
        ${'does not render when widget is not returned from API'} | ${false}                 | ${false}
      `('$description', ({ developmentWidgetPresent, exists }) => {
        const response = workItemResponseFactory({ developmentWidgetPresent });
        createComponent({ workItem: response.data.workItem, workItemsAlpha: false });

        expect(findWorkItemDevelopment().exists()).toBe(exists);
      });
    });

    describe('when `workItesMvc2` FF is on', () => {
      it.each`
        description                                               | developmentWidgetPresent | exists
        ${'renders when widget is returned from API'}             | ${true}                  | ${true}
        ${'does not render when widget is not returned from API'} | ${false}                 | ${false}
      `('$description', ({ developmentWidgetPresent, exists }) => {
        const response = workItemResponseFactory({ developmentWidgetPresent });
        createComponent({ workItem: response.data.workItem, workItemsAlpha: true });

        expect(findWorkItemDevelopment().exists()).toBe(exists);
      });
    });
  });
});
