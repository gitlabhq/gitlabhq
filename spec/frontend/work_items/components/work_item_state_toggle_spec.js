import { GlButton, GlLink } from '@gitlab/ui';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createMockApollo from 'helpers/mock_apollo_helper';
import { mockTracking } from 'helpers/tracking_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import WorkItemStateToggle from '~/work_items/components/work_item_state_toggle.vue';
import {
  STATE_OPEN,
  STATE_CLOSED,
  STATE_EVENT_CLOSE,
  STATE_EVENT_REOPEN,
  TRACKING_CATEGORY_SHOW,
} from '~/work_items/constants';
import { updateCountsForParent } from '~/work_items/graphql/cache_utils';
import updateWorkItemMutation from '~/work_items/graphql/update_work_item.mutation.graphql';
import workItemByIidQuery from '~/work_items/graphql/work_item_by_iid.query.graphql';
import workItemLinkedItemsQuery from '~/work_items/graphql/work_item_linked_items.query.graphql';
import workItemOpenChildCountQuery from '~/work_items/graphql/open_child_count.query.graphql';
import {
  updateWorkItemMutationResponse,
  mockBlockedByLinkedItem,
  workItemByIidResponseFactory,
  workItemBlockedByLinkedItemsResponse,
  workItemNoBlockedByLinkedItemsResponse,
  mockOpenChildrenCount,
  mockNoOpenChildrenCount,
} from '../mock_data';

jest.mock('~/work_items/graphql/cache_utils', () => ({
  updateCountsForParent: jest.fn(),
}));

describe('Work Item State toggle button component', () => {
  let wrapper;

  Vue.use(VueApollo);

  const workItemQueryResponse = workItemByIidResponseFactory();

  const mutationSuccessHandler = jest.fn().mockResolvedValue(updateWorkItemMutationResponse);
  const querySuccessHander = jest.fn().mockResolvedValue(workItemQueryResponse);
  const workItemBlockedByItemsSuccessHandler = jest
    .fn()
    .mockResolvedValue(workItemNoBlockedByLinkedItemsResponse);
  const openChildCountSuccessHandler = jest.fn().mockResolvedValue(mockNoOpenChildrenCount);

  const findStateToggleButton = () => wrapper.findComponent(GlButton);
  const findBlockedByModal = () => wrapper.findByTestId('blocked-by-issues-modal');
  const findBlockedByModalLinkAt = (index) =>
    findBlockedByModal().findAllComponents(GlLink).at(index);
  const findOpenChildrenModal = () => wrapper.findByTestId('open-children-warning-modal');

  const { id, iid } = workItemQueryResponse.data.workspace.workItem;

  const createComponent = ({
    mutationHandler = mutationSuccessHandler,
    workItemLinkedItemsHandler = workItemBlockedByItemsSuccessHandler,
    workItemOpenChildCountHandler = openChildCountSuccessHandler,
    canUpdate = true,
    workItemState = STATE_OPEN,
    workItemType = 'Task',
    hasComment = false,
    disabled = false,
    parentId = null,
  } = {}) => {
    wrapper = shallowMountExtended(WorkItemStateToggle, {
      apolloProvider: createMockApollo([
        [updateWorkItemMutation, mutationHandler],
        [workItemByIidQuery, querySuccessHander],
        [workItemLinkedItemsQuery, workItemLinkedItemsHandler],
        [workItemOpenChildCountQuery, workItemOpenChildCountHandler],
      ]),
      propsData: {
        workItemId: id,
        workItemIid: iid,
        fullPath: 'test-project-path',
        workItemState,
        workItemType,
        canUpdate,
        hasComment,
        disabled,
        parentId,
      },
    });
  };

  it('disables button when disabled prop is set', () => {
    createComponent({
      disabled: true,
    });

    expect(findStateToggleButton().props('disabled')).toBe(true);
  });

  describe('work item State button text', () => {
    it.each`
      workItemState   | workItemType    | buttonText
      ${STATE_OPEN}   | ${'Task'}       | ${'Close task'}
      ${STATE_CLOSED} | ${'Task'}       | ${'Reopen task'}
      ${STATE_OPEN}   | ${'Objective'}  | ${'Close objective'}
      ${STATE_CLOSED} | ${'Objective'}  | ${'Reopen objective'}
      ${STATE_OPEN}   | ${'Key result'} | ${'Close key result'}
      ${STATE_CLOSED} | ${'Key result'} | ${'Reopen key result'}
    `(
      'is "$buttonText" when "$workItemType" state is "$workItemState"',
      ({ workItemState, workItemType, buttonText }) => {
        createComponent({ workItemState, workItemType });

        expect(findStateToggleButton().text()).toBe(buttonText);
      },
    );

    it.each`
      workItemState   | workItemType    | buttonText
      ${STATE_OPEN}   | ${'Task'}       | ${'Comment & close task'}
      ${STATE_CLOSED} | ${'Task'}       | ${'Comment & reopen task'}
      ${STATE_OPEN}   | ${'Objective'}  | ${'Comment & close objective'}
      ${STATE_CLOSED} | ${'Objective'}  | ${'Comment & reopen objective'}
      ${STATE_OPEN}   | ${'Key result'} | ${'Comment & close key result'}
      ${STATE_CLOSED} | ${'Key result'} | ${'Comment & reopen key result'}
    `(
      'is "$buttonText" when "$workItemType" state is "$workItemState" and hasComment is true',
      ({ workItemState, workItemType, buttonText }) => {
        createComponent({ workItemState, workItemType, hasComment: true });

        expect(findStateToggleButton().text()).toBe(buttonText);
      },
    );
  });

  describe('when updating the state', () => {
    it('calls a mutation', () => {
      createComponent();

      findStateToggleButton().vm.$emit('click');

      expect(mutationSuccessHandler).toHaveBeenCalledWith({
        input: {
          id,
          stateEvent: STATE_EVENT_CLOSE,
        },
      });
    });

    it('calls a mutation with REOPEN', () => {
      createComponent({
        workItemState: STATE_CLOSED,
      });

      findStateToggleButton().vm.$emit('click');

      expect(mutationSuccessHandler).toHaveBeenCalledWith({
        input: {
          id,
          stateEvent: STATE_EVENT_REOPEN,
        },
      });
    });

    it('emits `submit-comment` when hasComment is true', async () => {
      createComponent({ hasComment: true });

      findStateToggleButton().vm.$emit('click');
      await waitForPromises();

      expect(wrapper.emitted('submit-comment')).toBeDefined();
    });

    it('emits an error message when the mutation was unsuccessful', async () => {
      createComponent({ mutationHandler: jest.fn().mockRejectedValue('Error!') });

      findStateToggleButton().vm.$emit('click');
      await waitForPromises();

      expect(wrapper.emitted('error')).toEqual([
        ['Something went wrong while updating the task. Please try again.'],
      ]);
    });

    it('tracks editing the state', async () => {
      const trackingSpy = mockTracking(undefined, wrapper.element, jest.spyOn);

      createComponent();

      findStateToggleButton().vm.$emit('click');
      await waitForPromises();

      expect(trackingSpy).toHaveBeenCalledWith(TRACKING_CATEGORY_SHOW, 'updated_state', {
        category: TRACKING_CATEGORY_SHOW,
        label: 'item_state',
        property: 'type_Task',
      });
    });

    describe('and the `parentId` prop is provided', () => {
      it('calls the `updateCountsForParent` cache util when changing the state', async () => {
        createComponent({ parentId: 'example-id' });

        findStateToggleButton().vm.$emit('click');

        await waitForPromises();

        expect(updateCountsForParent).toHaveBeenCalledWith({
          cache: expect.anything(Object),
          parentId: 'example-id',
          isClosing: true,
          workItemType: 'Task',
        });
      });
    });
  });

  describe('with blocking issues', () => {
    const blockers = mockBlockedByLinkedItem.linkedItems.nodes;

    beforeEach(async () => {
      createComponent({
        workItemLinkedItemsHandler: jest
          .fn()
          .mockResolvedValue(workItemBlockedByLinkedItemsResponse),
      });
      await waitForPromises();
    });

    it('has title text', () => {
      expect(findBlockedByModal().attributes('title')).toBe(
        'Are you sure you want to close this blocked task?',
      );
    });

    it('has body text', () => {
      expect(findBlockedByModal().text()).toContain(
        'This task is currently blocked by the following items:',
      );
    });

    describe.each`
      ordinal     | index
      ${'first'}  | ${0}
      ${'second'} | ${1}
    `('$ordinal blocked-by issue link', ({ index }) => {
      it('has link text', () => {
        expect(findBlockedByModalLinkAt(index).text()).toBe(`#${blockers[index].workItem.iid}`);
      });

      it('has url', () => {
        expect(findBlockedByModalLinkAt(index).attributes('href')).toBe(
          blockers[index].workItem.webUrl,
        );
      });
    });
  });

  describe('with open child items', () => {
    beforeEach(async () => {
      createComponent({
        workItemOpenChildCountHandler: jest.fn().mockResolvedValue(mockOpenChildrenCount),
        workItemType: 'Epic',
      });
      await waitForPromises();
    });

    it('has title text', () => {
      expect(findOpenChildrenModal().attributes('title')).toBe(
        'Are you sure you want to close this epic?',
      );
    });

    it('has body text', () => {
      expect(findOpenChildrenModal().text()).toContain(
        'This epic has open child items. If you close this epic, they will remain open.',
      );
    });
  });
});
