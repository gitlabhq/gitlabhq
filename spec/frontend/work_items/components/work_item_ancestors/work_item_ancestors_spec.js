import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { GlPopover } from '@gitlab/ui';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';

import { createAlert } from '~/alert';
import DisclosureHierarchy from '~/work_items/components/work_item_ancestors/disclosure_hierarchy.vue';
import WorkItemAncestors, {
  ANCESTOR_NOT_AVAILABLE,
} from '~/work_items/components/work_item_ancestors/work_item_ancestors.vue';
import workItemAncestorsQuery from '~/work_items/graphql/work_item_ancestors.query.graphql';
import workItemAncestorsUpdatedSubscription from '~/work_items/graphql/work_item_ancestors.subscription.graphql';
import { formatAncestors } from '~/work_items/utils';

import { workItemTask } from '../../mock_data';
import {
  workItemAncestorsQueryResponse,
  workItemEmptyAncestorsQueryResponse,
  workItemThreeAncestorsQueryResponse,
  workItemInaccessibleAncestorsQueryResponse,
  workItemMultipleInaccessibleAncestorsQueryResponse,
} from './mock_data';

Vue.use(VueApollo);
jest.mock('~/alert');

describe('WorkItemAncestors', () => {
  let wrapper;
  let mockApollo;

  const workItemAncestorsQueryHandler = jest.fn().mockResolvedValue(workItemAncestorsQueryResponse);
  const workItemEmptyAncestorsQueryHandler = jest
    .fn()
    .mockResolvedValue(workItemEmptyAncestorsQueryResponse);
  const workItemThreeAncestorsQueryHandler = jest
    .fn()
    .mockResolvedValue(workItemThreeAncestorsQueryResponse);
  const workItemAncestorsFailureHandler = jest.fn().mockRejectedValue(new Error());
  const workItemAncestorsUpdatedSubscriptionHandler = jest
    .fn()
    .mockResolvedValue({ data: { workItemUpdated: null } });

  const findDisclosureHierarchy = () => wrapper.findComponent(DisclosureHierarchy);
  const findPopover = () => wrapper.findComponent(GlPopover);

  const createComponent = ({
    props = {},
    options = {},
    ancestorsQueryHandler = workItemAncestorsQueryHandler,
  } = {}) => {
    mockApollo = createMockApollo([
      [workItemAncestorsQuery, ancestorsQueryHandler],
      [workItemAncestorsUpdatedSubscription, workItemAncestorsUpdatedSubscriptionHandler],
    ]);
    return mountExtended(WorkItemAncestors, {
      apolloProvider: mockApollo,
      propsData: {
        workItem: workItemTask,
        ...props,
      },
      ...options,
    });
  };

  beforeEach(async () => {
    createAlert.mockClear();
    wrapper = createComponent();
    await waitForPromises();
  });

  it('fetches work item ancestors', () => {
    expect(workItemAncestorsQueryHandler).toHaveBeenCalled();
  });

  it('displays DisclosureHierarchy component with ancestors when work item has at least one ancestor', () => {
    expect(findDisclosureHierarchy().exists()).toBe(true);
    expect(findDisclosureHierarchy().props('items')).toEqual(
      expect.objectContaining(formatAncestors(workItemAncestorsQueryResponse.data.workItem)),
    );
  });

  it('does not include `ANCESTOR_NOT_AVAILABLE` item when ancestors are accessible', () => {
    expect(findDisclosureHierarchy().props('items')).toEqual(
      expect.not.objectContaining(ANCESTOR_NOT_AVAILABLE),
    );
  });

  it('does not display DisclosureHierarchy component when work item has no ancestor', async () => {
    wrapper = createComponent({ ancestorsQueryHandler: workItemEmptyAncestorsQueryHandler });
    await waitForPromises();

    expect(findDisclosureHierarchy().exists()).toBe(false);
  });

  it('displays work item info in popover on hover and focus', () => {
    expect(findPopover().exists()).toBe(true);
    expect(findPopover().props('triggers')).toBe('hover focus');

    const ancestor = findDisclosureHierarchy().props('items')[0];

    expect(findPopover().text()).toContain(ancestor.title);
    expect(findPopover().text()).toContain(ancestor.reference);
  });

  it('calls the work item updated subscription', () => {
    expect(workItemAncestorsUpdatedSubscriptionHandler).toHaveBeenCalledWith({
      id: workItemTask.id,
    });
  });

  describe('when work item has less than 3 ancestors', () => {
    it('does not activate ellipsis option for DisclosureHierarchy component', () => {
      expect(findDisclosureHierarchy().props('withEllipsis')).toBe(false);
    });
  });

  describe('when work item has at least 3 ancestors', () => {
    beforeEach(async () => {
      wrapper = createComponent({ ancestorsQueryHandler: workItemThreeAncestorsQueryHandler });
      await waitForPromises();
    });

    it('activates ellipsis option for DisclosureHierarchy component', () => {
      expect(findDisclosureHierarchy().props('withEllipsis')).toBe(true);
      expect(findDisclosureHierarchy().props('items')).toEqual(
        expect.objectContaining(formatAncestors(workItemThreeAncestorsQueryResponse.data.workItem)),
      );
    });
  });

  it('creates alert when the query fails', async () => {
    createComponent({ ancestorsQueryHandler: workItemAncestorsFailureHandler });
    await waitForPromises();

    expect(createAlert).toHaveBeenCalledWith({
      captureError: true,
      error: expect.any(Object),
      message: 'Something went wrong while fetching ancestors.',
    });
  });

  describe('when user has no permission to view ancestors', () => {
    const workItemInaccessibleRootLevelAncestorsQueryHandler = jest
      .fn()
      .mockResolvedValue(workItemInaccessibleAncestorsQueryResponse);

    const workItemMultipleInaccessibleAncestorsQueryHandler = jest
      .fn()
      .mockResolvedValue(workItemMultipleInaccessibleAncestorsQueryResponse);

    beforeEach(async () => {
      wrapper = createComponent({
        ancestorsQueryHandler: workItemInaccessibleRootLevelAncestorsQueryHandler,
      });
      await waitForPromises();
    });

    it('displays appropriate message in popover on hover and focus', () => {
      expect(findPopover().exists()).toBe(true);
      expect(findPopover().props('triggers')).toBe('hover focus');
      expect(findPopover().text()).toEqual(
        `You don't have the necessary permission to view the ancestors.`,
      );
    });

    describe('DisclosureHierarchy component', () => {
      it('includes `ANCESTOR_NOT_AVAILABLE` item when there is parent is at root level', () => {
        expect(findDisclosureHierarchy().props('items')).toEqual([ANCESTOR_NOT_AVAILABLE]);
      });

      it('includes `ANCESTOR_NOT_AVAILABLE` item with accessible parent if there are multiple ancestors', async () => {
        wrapper = createComponent({
          ancestorsQueryHandler: workItemMultipleInaccessibleAncestorsQueryHandler,
        });
        await waitForPromises();

        expect(findDisclosureHierarchy().props('items')).toEqual(
          expect.arrayContaining([
            ANCESTOR_NOT_AVAILABLE,
            ...formatAncestors(workItemMultipleInaccessibleAncestorsQueryResponse.data.workItem),
          ]),
        );
      });
    });
  });
});
