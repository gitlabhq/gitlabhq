import { mount } from '@vue/test-utils';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import workItemWeightSubscription from 'ee_component/work_items/graphql/work_item_weight.subscription.graphql';
import createMockApollo from 'helpers/mock_apollo_helper';
import {
  workItemAssigneesSubscriptionResponse,
  workItemDatesSubscriptionResponse,
  workItemResponseFactory,
  workItemTitleSubscriptionResponse,
  workItemWeightSubscriptionResponse,
} from 'jest/work_items/mock_data';
import App from '~/work_items/components/app.vue';
import workItemQuery from '~/work_items/graphql/work_item.query.graphql';
import workItemDatesSubscription from '~/work_items/graphql/work_item_dates.subscription.graphql';
import workItemTitleSubscription from '~/work_items/graphql/work_item_title.subscription.graphql';
import workItemAssigneesSubscription from '~/work_items/graphql/work_item_assignees.subscription.graphql';
import CreateWorkItem from '~/work_items/pages/create_work_item.vue';
import WorkItemsRoot from '~/work_items/pages/work_item_root.vue';
import { createRouter } from '~/work_items/router';

describe('Work items router', () => {
  let wrapper;

  Vue.use(VueApollo);

  const workItemQueryHandler = jest.fn().mockResolvedValue(workItemResponseFactory());
  const datesSubscriptionHandler = jest.fn().mockResolvedValue(workItemDatesSubscriptionResponse);
  const titleSubscriptionHandler = jest.fn().mockResolvedValue(workItemTitleSubscriptionResponse);
  const weightSubscriptionHandler = jest.fn().mockResolvedValue(workItemWeightSubscriptionResponse);
  const assigneesSubscriptionHandler = jest
    .fn()
    .mockResolvedValue(workItemAssigneesSubscriptionResponse);

  const createComponent = async (routeArg) => {
    const router = createRouter('/work_item');
    if (routeArg !== undefined) {
      await router.push(routeArg);
    }

    const handlers = [
      [workItemQuery, workItemQueryHandler],
      [workItemDatesSubscription, datesSubscriptionHandler],
      [workItemTitleSubscription, titleSubscriptionHandler],
      [workItemAssigneesSubscription, assigneesSubscriptionHandler],
    ];

    if (IS_EE) {
      handlers.push([workItemWeightSubscription, weightSubscriptionHandler]);
    }

    wrapper = mount(App, {
      apolloProvider: createMockApollo(handlers),
      router,
      provide: {
        fullPath: 'full-path',
        issuesListPath: 'full-path/-/issues',
      },
    });
  };

  afterEach(() => {
    wrapper.destroy();
    window.location.hash = '';
  });

  it('renders work item on `/1` route', async () => {
    await createComponent('/1');

    expect(wrapper.findComponent(WorkItemsRoot).exists()).toBe(true);
  });

  it('renders create work item page on `/new` route', async () => {
    await createComponent('/new');

    expect(wrapper.findComponent(CreateWorkItem).exists()).toBe(true);
  });
});
