import { nextTick } from 'vue';
import { shallowMount } from '@vue/test-utils';
import WorkItemAssignees from '~/work_items/components/work_item_assignees.vue';
import WorkItemDueDate from '~/work_items/components/work_item_due_date.vue';
import WorkItemLabels from '~/work_items/components/work_item_labels.vue';
import WorkItemMilestone from '~/work_items/components/work_item_milestone.vue';
import WorkItemParentInline from '~/work_items/components/work_item_parent_inline.vue';
import WorkItemParent from '~/work_items/components/work_item_parent_with_edit.vue';
import waitForPromises from 'helpers/wait_for_promises';
import WorkItemAttributesWrapper from '~/work_items/components/work_item_attributes_wrapper.vue';
import {
  workItemResponseFactory,
  taskType,
  issueType,
  objectiveType,
  keyResultType,
} from '../mock_data';

describe('WorkItemAttributesWrapper component', () => {
  let wrapper;

  const workItemQueryResponse = workItemResponseFactory({ canUpdate: true, canDelete: true });

  const findWorkItemDueDate = () => wrapper.findComponent(WorkItemDueDate);
  const findWorkItemAssignees = () => wrapper.findComponent(WorkItemAssignees);
  const findWorkItemLabels = () => wrapper.findComponent(WorkItemLabels);
  const findWorkItemMilestone = () => wrapper.findComponent(WorkItemMilestone);
  const findWorkItemParentInline = () => wrapper.findComponent(WorkItemParentInline);
  const findWorkItemParent = () => wrapper.findComponent(WorkItemParent);

  const createComponent = ({
    workItem = workItemQueryResponse.data.workItem,
    workItemsMvc2 = true,
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
          workItemsMvc2,
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
  });

  describe('parent widget', () => {
    describe.each`
      description                           | workItemType     | exists
      ${'when work item type is task'}      | ${taskType}      | ${true}
      ${'when work item type is objective'} | ${objectiveType} | ${true}
      ${'when work item type is keyresult'} | ${keyResultType} | ${true}
      ${'when work item type is issue'}     | ${issueType}     | ${false}
    `('$description', ({ workItemType, exists }) => {
      it(`${exists ? 'renders' : 'does not render'} parent component`, async () => {
        const response = workItemResponseFactory({ workItemType });
        createComponent({ workItem: response.data.workItem });

        await waitForPromises();

        expect(findWorkItemParent().exists()).toBe(exists);
      });
    });

    it('renders WorkItemParent when workItemsMvc2 enabled', async () => {
      createComponent();

      await waitForPromises();

      expect(findWorkItemParent().exists()).toBe(true);
      expect(findWorkItemParentInline().exists()).toBe(false);
    });

    it('renders WorkItemParentInline when workItemsMvc2 disabled', async () => {
      createComponent({ workItemsMvc2: false });

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
});
