import Vue from 'vue';
import { shallowMount } from '@vue/test-utils';
import VueApollo from 'vue-apollo';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { mockTracking, unmockTracking } from 'helpers/tracking_helper';
import workItemQuery from '~/work_items/graphql/work_item.query.graphql';
import updateWorkItemMutation from '~/work_items/graphql/update_work_item.mutation.graphql';
import WorkItemsRoot from '~/work_items/pages/work_item_root.vue';
import ItemTitle from '~/work_items/components/item_title.vue';
import { resolvers } from '~/work_items/graphql/resolvers';
import { workItemQueryResponse } from '../mock_data';

Vue.use(VueApollo);

const WORK_ITEM_ID = '1';

describe('Work items root component', () => {
  const mockUpdatedTitle = 'Updated title';
  let wrapper;
  let fakeApollo;

  const findTitle = () => wrapper.findComponent(ItemTitle);

  const createComponent = ({ queryResponse = workItemQueryResponse } = {}) => {
    fakeApollo = createMockApollo([], resolvers, {
      possibleTypes: {
        LocalWorkItemWidget: ['LocalTitleWidget'],
      },
    });
    fakeApollo.clients.defaultClient.cache.writeQuery({
      query: workItemQuery,
      variables: {
        id: WORK_ITEM_ID,
      },
      data: queryResponse,
    });

    wrapper = shallowMount(WorkItemsRoot, {
      propsData: {
        id: WORK_ITEM_ID,
      },
      apolloProvider: fakeApollo,
    });
  };

  afterEach(() => {
    wrapper.destroy();
    fakeApollo = null;
  });

  it('renders the title if title is in the widgets list', () => {
    createComponent();

    expect(findTitle().exists()).toBe(true);
    expect(findTitle().props('initialTitle')).toBe('Test');
  });

  it('updates the title when it is edited', async () => {
    createComponent();
    jest.spyOn(wrapper.vm.$apollo, 'mutate');

    await findTitle().vm.$emit('title-changed', mockUpdatedTitle);

    expect(wrapper.vm.$apollo.mutate).toHaveBeenCalledWith({
      mutation: updateWorkItemMutation,
      variables: {
        input: {
          id: WORK_ITEM_ID,
          title: mockUpdatedTitle,
        },
      },
    });

    await waitForPromises();
    expect(findTitle().props('initialTitle')).toBe(mockUpdatedTitle);
  });

  it('does not render the title if title is not in the widgets list', () => {
    const queryResponse = {
      workItem: {
        ...workItemQueryResponse.workItem,
        widgets: {
          __typename: 'WorkItemWidgetConnection',
          nodes: [
            {
              __typename: 'SomeOtherWidget',
              type: 'OTHER',
              contentText: 'Test',
            },
          ],
        },
      },
    };
    createComponent({ queryResponse });

    expect(findTitle().exists()).toBe(false);
  });

  describe('tracking', () => {
    let trackingSpy;

    beforeEach(() => {
      trackingSpy = mockTracking('_category_', undefined, jest.spyOn);

      createComponent();
    });

    afterEach(() => {
      unmockTracking();
    });

    it('tracks item title updates', async () => {
      await findTitle().vm.$emit('title-changed', mockUpdatedTitle);

      await waitForPromises();

      expect(trackingSpy).toHaveBeenCalledTimes(1);
      expect(trackingSpy).toHaveBeenCalledWith('workItems:show', undefined, {
        action: 'updated_title',
        category: 'workItems:show',
        label: 'item_title',
        property: '[type_work_item]',
      });
    });
  });
});
