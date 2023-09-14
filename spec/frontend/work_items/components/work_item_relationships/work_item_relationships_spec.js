import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { GlLoadingIcon } from '@gitlab/ui';

import createMockApollo from 'helpers/mock_apollo_helper';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';

import WidgetWrapper from '~/work_items/components/widget_wrapper.vue';
import WorkItemRelationships from '~/work_items/components/work_item_relationships/work_item_relationships.vue';
import WorkItemRelationshipList from '~/work_items/components/work_item_relationships/work_item_relationship_list.vue';
import workItemByIidQuery from '~/work_items/graphql/work_item_by_iid.query.graphql';

import {
  workItemByIidResponseFactory,
  mockLinkedItems,
  mockBlockingLinkedItem,
} from '../../mock_data';

describe('WorkItemRelationships', () => {
  Vue.use(VueApollo);

  let wrapper;
  const emptyLinkedWorkItemsQueryHandler = jest
    .fn()
    .mockResolvedValue(workItemByIidResponseFactory());
  const linkedWorkItemsQueryHandler = jest
    .fn()
    .mockResolvedValue(workItemByIidResponseFactory({ linkedItems: mockLinkedItems }));
  const blockingLinkedWorkItemQueryHandler = jest
    .fn()
    .mockResolvedValue(workItemByIidResponseFactory({ linkedItems: mockBlockingLinkedItem }));

  const createComponent = async ({
    workItemQueryHandler = emptyLinkedWorkItemsQueryHandler,
  } = {}) => {
    const mockApollo = createMockApollo([[workItemByIidQuery, workItemQueryHandler]]);

    wrapper = shallowMountExtended(WorkItemRelationships, {
      apolloProvider: mockApollo,
      propsData: {
        workItemIid: '1',
        workItemFullPath: 'test-project-path',
      },
    });

    await waitForPromises();
  };

  const findLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);
  const findWidgetWrapper = () => wrapper.findComponent(WidgetWrapper);
  const findEmptyRelatedMessageContainer = () => wrapper.findByTestId('links-empty');
  const findLinkedItemsCountContainer = () => wrapper.findByTestId('linked-items-count');
  const findAllWorkItemRelationshipListComponents = () =>
    wrapper.findAllComponents(WorkItemRelationshipList);

  it('shows loading icon when query is not processed', () => {
    createComponent();

    expect(findLoadingIcon().exists()).toBe(true);
  });

  it('renders the component with empty message when there are no items', async () => {
    await createComponent();

    expect(wrapper.find('.work-item-relationships').exists()).toBe(true);
    expect(findEmptyRelatedMessageContainer().exists()).toBe(true);
  });

  it('renders blocking linked item lists', async () => {
    await createComponent({ workItemQueryHandler: blockingLinkedWorkItemQueryHandler });

    expect(findAllWorkItemRelationshipListComponents().length).toBe(1);
    expect(findLinkedItemsCountContainer().text()).toBe('1');
  });

  it('renders blocking, blocked by and related to linked item lists with proper count', async () => {
    await createComponent({ workItemQueryHandler: linkedWorkItemsQueryHandler });

    // renders all 3 lists: blocking, blocked by and related to
    expect(findAllWorkItemRelationshipListComponents().length).toBe(3);
    expect(findLinkedItemsCountContainer().text()).toBe('3');
  });

  it('shows an alert when list loading fails', async () => {
    const errorMessage = 'Some error';
    await createComponent({
      workItemQueryHandler: jest.fn().mockRejectedValue(new Error(errorMessage)),
    });

    expect(findWidgetWrapper().props('error')).toBe(errorMessage);
  });
});
