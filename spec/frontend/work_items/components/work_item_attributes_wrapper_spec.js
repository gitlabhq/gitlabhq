import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import { shallowMount } from '@vue/test-utils';
import Participants from '~/sidebar/components/participants/participants.vue';
import WorkItemAssignees from '~/work_items/components/work_item_assignees.vue';
import WorkItemDueDate from '~/work_items/components/work_item_due_date.vue';
import WorkItemLabels from '~/work_items/components/work_item_labels.vue';
import WorkItemMilestone from '~/work_items/components/work_item_milestone.vue';
import WorkItemParent from '~/work_items/components/work_item_parent.vue';
import WorkItemTimeTracking from '~/work_items/components/work_item_time_tracking.vue';
import WorkItemCrmContacts from '~/work_items/components/work_item_crm_contacts.vue';
import waitForPromises from 'helpers/wait_for_promises';
import createMockApollo from 'helpers/mock_apollo_helper';
import WorkItemAttributesWrapper from '~/work_items/components/work_item_attributes_wrapper.vue';
import workItemParticipantsQuery from '~/work_items/graphql/work_item_participants.query.graphql';
import getAllowedWorkItemParentTypes from '~/work_items/graphql/work_item_allowed_parent_types.query.graphql';
import {
  workItemResponseFactory,
  mockParticipantWidget,
  allowedParentTypesResponse,
  allowedParentTypesEmptyResponse,
} from '../mock_data';

describe('WorkItemAttributesWrapper component', () => {
  let wrapper;

  Vue.use(VueApollo);

  const workItemQueryResponse = workItemResponseFactory({
    canUpdate: true,
    canDelete: true,
    participantsWidgetPresent: false,
  });
  const workItemParticipantsQueryResponse = {
    data: {
      workspace: {
        __typename: 'Namespace',
        id: workItemQueryResponse.data.workItem.namespace.id,
        workItem: {
          id: workItemQueryResponse.data.workItem.id,
          widgets: [...workItemQueryResponse.data.workItem.widgets, mockParticipantWidget],
        },
      },
    },
  };
  const workItemParticipantsQuerySuccessHandler = jest
    .fn()
    .mockResolvedValue(workItemParticipantsQueryResponse);
  const workItemParticipantsQueryFailureHandler = jest.fn().mockRejectedValue(new Error());

  const allowedParentTypesSuccessHandler = jest.fn().mockResolvedValue(allowedParentTypesResponse);
  const allowedParentTypesEmptyHandler = jest
    .fn()
    .mockResolvedValue(allowedParentTypesEmptyResponse);

  const findWorkItemAssignees = () => wrapper.findComponent(WorkItemAssignees);
  const findWorkItemDueDate = () => wrapper.findComponent(WorkItemDueDate);
  const findWorkItemLabels = () => wrapper.findComponent(WorkItemLabels);
  const findWorkItemMilestone = () => wrapper.findComponent(WorkItemMilestone);
  const findWorkItemParent = () => wrapper.findComponent(WorkItemParent);
  const findWorkItemTimeTracking = () => wrapper.findComponent(WorkItemTimeTracking);
  const findWorkItemParticipants = () => wrapper.findComponent(Participants);
  const findWorkItemCrmContacts = () => wrapper.findComponent(WorkItemCrmContacts);

  const createComponent = ({
    workItem = workItemQueryResponse.data.workItem,
    workItemsAlpha = false,
    groupPath = '',
    workItemParticipantsQueryHandler = workItemParticipantsQuerySuccessHandler,
    allowedParentTypesHandler = allowedParentTypesSuccessHandler,
  } = {}) => {
    wrapper = shallowMount(WorkItemAttributesWrapper, {
      apolloProvider: createMockApollo([
        [workItemParticipantsQuery, workItemParticipantsQueryHandler],
        [getAllowedWorkItemParentTypes, allowedParentTypesHandler],
      ]),
      propsData: {
        fullPath: 'group/project',
        workItem,
        groupPath,
        isGroup: false,
      },
      provide: {
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
    it(`renders parent component`, async () => {
      const response = workItemResponseFactory();
      createComponent({ workItem: response.data.workItem });

      await waitForPromises();

      expect(findWorkItemParent().exists()).toBe(true);
    });

    it('does not render parent component if it is not supported by the license', async () => {
      createComponent({ allowedParentTypesHandler: allowedParentTypesEmptyHandler });
      await waitForPromises();

      expect(findWorkItemParent().exists()).toBe(false);
    });

    it.each([true, false])(`renders parent component with hasParent %s`, async (hasParent) => {
      const response = workItemResponseFactory({ hasParent });
      createComponent({ workItem: response.data.workItem });

      await waitForPromises();

      expect(findWorkItemParent().props('hasParent')).toBe(hasParent);
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

  describe('CRM contacts widget', () => {
    describe('when workItemsAlpha FF is disabled', () => {
      it.each`
        description                                               | crmContactsWidgetPresent | exists
        ${'renders when widget is returned from API'}             | ${true}                  | ${false}
        ${'does not render when widget is not returned from API'} | ${false}                 | ${false}
      `('$description', ({ crmContactsWidgetPresent, exists }) => {
        const response = workItemResponseFactory({ crmContactsWidgetPresent });
        createComponent({ workItem: response.data.workItem });

        expect(findWorkItemCrmContacts().exists()).toBe(exists);
      });
    });

    describe('when workItemsAlpha FF is enabled', () => {
      it.each`
        description                                               | crmContactsWidgetPresent | exists
        ${'renders when widget is returned from API'}             | ${true}                  | ${true}
        ${'does not render when widget is not returned from API'} | ${false}                 | ${false}
      `('$description', ({ crmContactsWidgetPresent, exists }) => {
        const response = workItemResponseFactory({ crmContactsWidgetPresent });
        createComponent({ workItem: response.data.workItem, workItemsAlpha: true });

        expect(findWorkItemCrmContacts().exists()).toBe(exists);
      });
    });
  });

  describe('participants widget', () => {
    it.each`
      description                                               | workItemParticipantsQueryHandler           | exists
      ${'renders when widget is returned from API'}             | ${workItemParticipantsQuerySuccessHandler} | ${true}
      ${'does not render when widget is not returned from API'} | ${workItemParticipantsQueryFailureHandler} | ${false}
    `('$description', async ({ workItemParticipantsQueryHandler, exists }) => {
      createComponent({ workItemParticipantsQueryHandler });

      await waitForPromises();

      expect(findWorkItemParticipants().exists()).toBe(exists);
    });
  });
});
