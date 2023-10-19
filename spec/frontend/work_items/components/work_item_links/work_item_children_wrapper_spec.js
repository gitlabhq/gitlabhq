import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';

import createMockApollo from 'helpers/mock_apollo_helper';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import WorkItemChildrenWrapper from '~/work_items/components/work_item_links/work_item_children_wrapper.vue';
import WorkItemLinkChild from '~/work_items/components/work_item_links/work_item_link_child.vue';
import updateWorkItemMutation from '~/work_items/graphql/update_work_item.mutation.graphql';
import workItemByIidQuery from '~/work_items/graphql/work_item_by_iid.query.graphql';

import { DEFAULT_DEBOUNCE_AND_THROTTLE_MS } from '~/lib/utils/constants';

import {
  changeWorkItemParentMutationResponse,
  childrenWorkItems,
  updateWorkItemMutationErrorResponse,
  workItemByIidResponseFactory,
} from '../../mock_data';

describe('WorkItemChildrenWrapper', () => {
  let wrapper;

  const $toast = {
    show: jest.fn(),
  };
  const getWorkItemQueryHandler = jest.fn().mockResolvedValue(workItemByIidResponseFactory());
  const updateWorkItemMutationHandler = jest
    .fn()
    .mockResolvedValue(changeWorkItemParentMutationResponse);

  const findWorkItemLinkChildItems = () => wrapper.findAllComponents(WorkItemLinkChild);

  Vue.use(VueApollo);

  const createComponent = ({
    workItemType = 'Objective',
    confidential = false,
    children = childrenWorkItems,
    mutationHandler = updateWorkItemMutationHandler,
  } = {}) => {
    const mockApollo = createMockApollo([
      [workItemByIidQuery, getWorkItemQueryHandler],
      [updateWorkItemMutation, mutationHandler],
    ]);

    mockApollo.clients.defaultClient.cache.writeQuery({
      query: workItemByIidQuery,
      variables: { fullPath: 'test/project', iid: '1' },
      data: workItemByIidResponseFactory().data,
    });

    wrapper = shallowMountExtended(WorkItemChildrenWrapper, {
      apolloProvider: mockApollo,
      provide: {
        isGroup: false,
      },
      propsData: {
        fullPath: 'test/project',
        workItemType,
        workItemId: 'gid://gitlab/WorkItem/515',
        workItemIid: '1',
        confidential,
        children,
      },
      mocks: {
        $toast,
      },
    });
  };

  it('renders all hierarchy widget children', () => {
    createComponent();

    const workItemLinkChildren = findWorkItemLinkChildItems();
    expect(workItemLinkChildren).toHaveLength(4);
    expect(workItemLinkChildren.at(0).props().childItem.confidential).toBe(
      childrenWorkItems[0].confidential,
    );
  });

  it('emits `show-modal` on `click` event', () => {
    createComponent();
    const firstChild = findWorkItemLinkChildItems().at(0);
    const event = {
      childItem: 'gid://gitlab/WorkItem/2',
    };

    firstChild.vm.$emit('click', event);

    expect(wrapper.emitted('show-modal')).toEqual([[{ event, child: event.childItem }]]);
  });

  it.each`
    description            | workItemType   | prefetch
    ${'prefetches'}        | ${'Issue'}     | ${true}
    ${'does not prefetch'} | ${'Objective'} | ${false}
  `(
    '$description work-item-link-child on mouseover when workItemType is "$workItemType"',
    async ({ workItemType, prefetch }) => {
      createComponent({ workItemType });
      const firstChild = findWorkItemLinkChildItems().at(0);
      firstChild.vm.$emit('mouseover', childrenWorkItems[0]);
      await nextTick();
      await waitForPromises();

      jest.advanceTimersByTime(DEFAULT_DEBOUNCE_AND_THROTTLE_MS);

      if (prefetch) {
        expect(getWorkItemQueryHandler).toHaveBeenCalled();
      } else {
        expect(getWorkItemQueryHandler).not.toHaveBeenCalled();
      }
    },
  );

  describe('when removing child work item', () => {
    const workItem = { id: 'gid://gitlab/WorkItem/2' };

    describe('when successful', () => {
      beforeEach(async () => {
        createComponent();
        findWorkItemLinkChildItems().at(0).vm.$emit('removeChild', workItem);
        await waitForPromises();
      });

      it('calls a mutation to update the work item', () => {
        expect(updateWorkItemMutationHandler).toHaveBeenCalledWith({
          input: {
            id: workItem.id,
            hierarchyWidget: {
              parentId: null,
            },
          },
        });
      });

      it('shows a toast', () => {
        expect($toast.show).toHaveBeenCalledWith('Child removed', {
          action: { onClick: expect.anything(), text: 'Undo' },
        });
      });
    });

    describe('when not successful', () => {
      beforeEach(async () => {
        createComponent({
          mutationHandler: jest.fn().mockResolvedValue(updateWorkItemMutationErrorResponse),
        });
        findWorkItemLinkChildItems().at(0).vm.$emit('removeChild', workItem);
        await waitForPromises();
      });

      it('emits an error message', () => {
        expect(wrapper.emitted('error')).toEqual([['Something went wrong while removing child.']]);
      });
    });
  });
});
