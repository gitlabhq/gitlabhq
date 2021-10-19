import { shallowMount, createLocalVue } from '@vue/test-utils';
import VueApollo from 'vue-apollo';
import createMockApollo from 'helpers/mock_apollo_helper';
import workItemQuery from '~/work_items/graphql/work_item.query.graphql';
import WorkItemsRoot from '~/work_items/pages/work_item_root.vue';
import { workItemQueryResponse } from '../mock_data';

const localVue = createLocalVue();
localVue.use(VueApollo);

const WORK_ITEM_ID = '1';

describe('Work items root component', () => {
  let wrapper;
  let fakeApollo;

  const findTitle = () => wrapper.find('[data-testid="title"]');

  const createComponent = ({ queryResponse = workItemQueryResponse } = {}) => {
    fakeApollo = createMockApollo();
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
      localVue,
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
    expect(findTitle().text()).toBe('Test');
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
});
