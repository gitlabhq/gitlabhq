import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';

import createMockApollo from 'helpers/mock_apollo_helper';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import WorkItemChildrenWrapper from '~/work_items/components/work_item_links/work_item_children_wrapper.vue';
import WorkItemLinkChild from '~/work_items/components/work_item_links/work_item_link_child.vue';
import workItemByIidQuery from '~/work_items/graphql/work_item_by_iid.query.graphql';

import { DEFAULT_DEBOUNCE_AND_THROTTLE_MS } from '~/lib/utils/constants';

import { childrenWorkItems, workItemByIidResponseFactory } from '../../mock_data';

describe('WorkItemChildrenWrapper', () => {
  let wrapper;

  const getWorkItemQueryHandler = jest.fn().mockResolvedValue(workItemByIidResponseFactory());

  const findWorkItemLinkChildItems = () => wrapper.findAllComponents(WorkItemLinkChild);

  Vue.use(VueApollo);

  const createComponent = ({
    workItemType = 'Objective',
    confidential = false,
    children = childrenWorkItems,
  } = {}) => {
    wrapper = shallowMountExtended(WorkItemChildrenWrapper, {
      apolloProvider: createMockApollo([[workItemByIidQuery, getWorkItemQueryHandler]]),
      propsData: {
        workItemType,
        workItemId: 'gid://gitlab/WorkItem/515',
        confidential,
        children,
        projectPath: 'test/project',
        fetchByIid: true,
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

  it('remove event on child triggers `removeChild` event', () => {
    createComponent();
    const firstChild = findWorkItemLinkChildItems().at(0);

    firstChild.vm.$emit('removeChild', 'gid://gitlab/WorkItem/2');

    expect(wrapper.emitted('removeChild')).toEqual([['gid://gitlab/WorkItem/2']]);
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
});
