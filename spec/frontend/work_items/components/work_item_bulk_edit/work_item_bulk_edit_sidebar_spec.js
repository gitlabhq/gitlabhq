import { GlForm } from '@gitlab/ui';
import MockAdapter from 'axios-mock-adapter';
import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import createMockApollo from 'helpers/mock_apollo_helper';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { createAlert } from '~/alert';
import axios from '~/lib/utils/axios_utils';
import { HTTP_STATUS_BAD_REQUEST, HTTP_STATUS_OK } from '~/lib/utils/http_status';
import WorkItemBulkEditAssignee from '~/work_items/components/work_item_bulk_edit/work_item_bulk_edit_assignee.vue';
import WorkItemBulkEditLabels from '~/work_items/components/work_item_bulk_edit/work_item_bulk_edit_labels.vue';
import WorkItemBulkEditSidebar from '~/work_items/components/work_item_bulk_edit/work_item_bulk_edit_sidebar.vue';
import workItemBulkUpdateMutation from '~/work_items/graphql/list/work_item_bulk_update.mutation.graphql';
import workItemParentQuery from '~/work_items/graphql/list//work_item_parent.query.graphql';
import { workItemParentQueryResponse } from '../../mock_data';

jest.mock('~/alert');

Vue.use(VueApollo);

describe('WorkItemBulkEditSidebar component', () => {
  let axiosMock;
  let wrapper;

  const checkedItems = [
    { id: 'gid://gitlab/WorkItem/11', title: 'Work Item 11' },
    { id: 'gid://gitlab/WorkItem/22', title: 'Work Item 22' },
  ];

  const workItemParentQueryHandler = jest.fn().mockResolvedValue(workItemParentQueryResponse);
  const workItemBulkUpdateHandler = jest
    .fn()
    .mockResolvedValue({ data: { workItemBulkUpdate: { updatedWorkItemCount: 1 } } });

  const createComponent = ({
    provide = {},
    props = {},
    mutationHandler = workItemBulkUpdateHandler,
  } = {}) => {
    wrapper = shallowMountExtended(WorkItemBulkEditSidebar, {
      apolloProvider: createMockApollo([
        [workItemParentQuery, workItemParentQueryHandler],
        [workItemBulkUpdateMutation, mutationHandler],
      ]),
      provide: {
        hasIssuableHealthStatusFeature: false,
        ...provide,
      },
      propsData: {
        checkedItems,
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

  beforeEach(() => {
    axiosMock = new MockAdapter(axios);
  });

  afterEach(() => {
    axiosMock.restore();
  });

  describe('form', () => {
    it('renders', () => {
      createComponent();

      expect(findForm().attributes('id')).toBe('work-item-list-bulk-edit');
    });

    describe('when epics list', () => {
      it('calls mutation to bulk edit', async () => {
        const addLabelIds = ['gid://gitlab/Label/1'];
        const removeLabelIds = ['gid://gitlab/Label/2'];
        createComponent({ props: { isEpicsList: true } });
        await waitForPromises();

        findAddLabelsComponent().vm.$emit('select', addLabelIds);
        findRemoveLabelsComponent().vm.$emit('select', removeLabelIds);
        findForm().vm.$emit('submit', { preventDefault: () => {} });

        expect(workItemBulkUpdateHandler).toHaveBeenCalledWith({
          input: {
            parentId: 'gid://gitlab/Group/1',
            ids: ['gid://gitlab/WorkItem/11', 'gid://gitlab/WorkItem/22'],
            labelsWidget: {
              addLabelIds,
              removeLabelIds,
            },
          },
        });
        expect(findAddLabelsComponent().props('selectedLabelsIds')).toEqual([]);
        expect(findRemoveLabelsComponent().props('selectedLabelsIds')).toEqual([]);
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

    describe('when not epics list', () => {
      it('makes POST request to bulk edit', async () => {
        const issuable_ids = '11,22'; // eslint-disable-line camelcase
        const add_label_ids = [1, 2, 3]; // eslint-disable-line camelcase
        const assignee_ids = [5]; // eslint-disable-line camelcase
        const confidential = 'true';
        const health_status = 'on_track'; // eslint-disable-line camelcase
        const remove_label_ids = [4, 5, 6]; // eslint-disable-line camelcase
        const state_event = 'reopen'; // eslint-disable-line camelcase
        const subscription_event = 'subscribe'; // eslint-disable-line camelcase
        axiosMock.onPost().replyOnce(HTTP_STATUS_OK);
        createComponent({
          provide: { hasIssuableHealthStatusFeature: true },
          props: { isEpicsList: false },
        });

        findStateComponent().vm.$emit('input', state_event);
        findAssigneeComponent().vm.$emit('input', 'gid://gitlab/User/5');
        findAddLabelsComponent().vm.$emit('select', [
          'gid://gitlab/Label/1',
          'gid://gitlab/Label/2',
          'gid://gitlab/Label/3',
        ]);
        findRemoveLabelsComponent().vm.$emit('select', [
          'gid://gitlab/Label/4',
          'gid://gitlab/Label/5',
          'gid://gitlab/Label/6',
        ]);
        findHealthStatusComponent().vm.$emit('input', health_status);
        findSubscriptionComponent().vm.$emit('input', subscription_event);
        findConfidentialityComponent().vm.$emit('input', confidential);
        findForm().vm.$emit('submit', { preventDefault: () => {} });
        await waitForPromises();

        expect(axiosMock.history.post[0].url).toBe('/group/project/-/issues/bulk_update');
        expect(axiosMock.history.post[0].data).toBe(
          JSON.stringify({
            update: {
              add_label_ids,
              assignee_ids,
              confidential,
              health_status,
              issuable_ids,
              remove_label_ids,
              state_event,
              subscription_event,
            },
          }),
        );
      });

      it('renders error when there is a response error', async () => {
        axiosMock.onPost().replyOnce(HTTP_STATUS_BAD_REQUEST);
        createComponent({ props: { isEpicsList: false } });

        findForm().vm.$emit('submit', { preventDefault: () => {} });
        await waitForPromises();

        expect(createAlert).toHaveBeenCalledWith({
          captureError: true,
          error: new Error('Request failed with status code 400'),
          message: 'Something went wrong while bulk editing.',
        });
      });
    });
  });

  describe('workItemParent query', () => {
    it('is called when isEpicsList=true', () => {
      createComponent({ props: { isEpicsList: true } });

      expect(workItemParentQueryHandler).toHaveBeenCalled();
    });

    it('is not called when isEpicsList=false', () => {
      createComponent({ props: { isEpicsList: false } });

      expect(workItemParentQueryHandler).not.toHaveBeenCalled();
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
    it.each([true, false])('renders depending on isEpicsList prop', (isEpicsList) => {
      createComponent({ props: { isEpicsList } });

      expect(findAssigneeComponent().exists()).toBe(!isEpicsList);
    });

    it('updates assignee when "Assignee" component emits "input" event', async () => {
      createComponent();

      findAssigneeComponent().vm.$emit('input', 'gid://gitlab/User/5');
      await nextTick();

      expect(findAssigneeComponent().props('value')).toBe('gid://gitlab/User/5');
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
  });

  describe('"Health status" component', () => {
    it.each`
      isEpicsList | hasIssuableHealthStatusFeature | expected
      ${false}    | ${false}                       | ${false}
      ${false}    | ${true}                        | ${true}
      ${true}     | ${false}                       | ${false}
      ${true}     | ${true}                        | ${false}
    `(
      'renders only when isEpicsList=false and hasIssuableHealthStatusFeature=true',
      ({ isEpicsList, hasIssuableHealthStatusFeature, expected }) => {
        createComponent({ provide: { hasIssuableHealthStatusFeature }, props: { isEpicsList } });

        expect(findHealthStatusComponent().exists()).toBe(expected);
      },
    );

    it('updates health status when "Health status" component emits "input" event', async () => {
      createComponent({ provide: { hasIssuableHealthStatusFeature: true } });

      findHealthStatusComponent().vm.$emit('input', 'needs_attention');
      await nextTick();

      expect(findHealthStatusComponent().props('value')).toBe('needs_attention');
    });
  });

  describe('"Subscription" component', () => {
    it.each([true, false])('renders depending on isEpicsList prop', (isEpicsList) => {
      createComponent({ props: { isEpicsList } });

      expect(findSubscriptionComponent().exists()).toBe(!isEpicsList);
    });

    it('updates subscription when "Subscription" component emits "input" event', async () => {
      createComponent();

      findSubscriptionComponent().vm.$emit('input', 'unsubscribe');
      await nextTick();

      expect(findSubscriptionComponent().props('value')).toBe('unsubscribe');
    });
  });

  describe('"Confidentiality" component', () => {
    it.each([true, false])('renders depending on isEpicsList prop', (isEpicsList) => {
      createComponent({ props: { isEpicsList } });

      expect(findConfidentialityComponent().exists()).toBe(!isEpicsList);
    });

    it('updates confidentiality when "Confidentiality" component emits "input" event', async () => {
      createComponent();

      findConfidentialityComponent().vm.$emit('input', 'false');
      await nextTick();

      expect(findConfidentialityComponent().props('value')).toBe('false');
    });
  });
});
