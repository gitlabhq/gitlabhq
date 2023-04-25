import { mount } from '@vue/test-utils';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createMockApollo from 'helpers/mock_apollo_helper';
import {
  currentUserResponse,
  workItemAssigneesSubscriptionResponse,
  workItemDatesSubscriptionResponse,
  workItemByIidResponseFactory as workItemResponseFactory,
  workItemTitleSubscriptionResponse,
  workItemLabelsSubscriptionResponse,
  workItemMilestoneSubscriptionResponse,
  workItemDescriptionSubscriptionResponse,
} from 'jest/work_items/mock_data';
import currentUserQuery from '~/graphql_shared/queries/current_user.query.graphql';
import App from '~/work_items/components/app.vue';
import workItemByIidQuery from '~/work_items/graphql/work_item_by_iid.query.graphql';
import workItemDatesSubscription from '~/graphql_shared/subscriptions/work_item_dates.subscription.graphql';
import workItemTitleSubscription from '~/work_items/graphql/work_item_title.subscription.graphql';
import workItemAssigneesSubscription from '~/work_items/graphql/work_item_assignees.subscription.graphql';
import workItemLabelsSubscription from 'ee_else_ce/work_items/graphql/work_item_labels.subscription.graphql';
import workItemMilestoneSubscription from '~/work_items/graphql/work_item_milestone.subscription.graphql';
import workItemDescriptionSubscription from '~/work_items/graphql/work_item_description.subscription.graphql';
import CreateWorkItem from '~/work_items/pages/create_work_item.vue';
import WorkItemsRoot from '~/work_items/pages/work_item_root.vue';
import { createRouter } from '~/work_items/router';

jest.mock('~/behaviors/markdown/render_gfm');

describe('Work items router', () => {
  let wrapper;

  Vue.use(VueApollo);

  const workItemQueryHandler = jest.fn().mockResolvedValue(workItemResponseFactory());
  const currentUserQueryHandler = jest.fn().mockResolvedValue(currentUserResponse);
  const datesSubscriptionHandler = jest.fn().mockResolvedValue(workItemDatesSubscriptionResponse);
  const titleSubscriptionHandler = jest.fn().mockResolvedValue(workItemTitleSubscriptionResponse);
  const assigneesSubscriptionHandler = jest
    .fn()
    .mockResolvedValue(workItemAssigneesSubscriptionResponse);
  const labelsSubscriptionHandler = jest.fn().mockResolvedValue(workItemLabelsSubscriptionResponse);
  const milestoneSubscriptionHandler = jest
    .fn()
    .mockResolvedValue(workItemMilestoneSubscriptionResponse);
  const descriptionSubscriptionHandler = jest
    .fn()
    .mockResolvedValue(workItemDescriptionSubscriptionResponse);

  const createComponent = async (routeArg) => {
    const router = createRouter('/work_item');
    if (routeArg !== undefined) {
      await router.push(routeArg);
    }

    const handlers = [
      [workItemByIidQuery, workItemQueryHandler],
      [currentUserQuery, currentUserQueryHandler],
      [workItemDatesSubscription, datesSubscriptionHandler],
      [workItemTitleSubscription, titleSubscriptionHandler],
      [workItemAssigneesSubscription, assigneesSubscriptionHandler],
      [workItemLabelsSubscription, labelsSubscriptionHandler],
      [workItemMilestoneSubscription, milestoneSubscriptionHandler],
      [workItemDescriptionSubscription, descriptionSubscriptionHandler],
    ];

    wrapper = mount(App, {
      apolloProvider: createMockApollo(handlers),
      router,
      provide: {
        fullPath: 'full-path',
        issuesListPath: 'full-path/-/issues',
        hasIssueWeightsFeature: false,
        hasIterationsFeature: false,
        hasOkrsFeature: false,
        hasIssuableHealthStatusFeature: false,
        reportAbusePath: '/report/abuse/path',
      },
      stubs: {
        WorkItemWeight: true,
        WorkItemIteration: true,
        WorkItemHealthStatus: true,
        WorkItemNotes: true,
      },
    });
  };

  beforeEach(() => {
    window.gon = {
      features: {
        workItemsMvc2: false,
      },
    };
  });

  afterEach(() => {
    window.location.hash = '';
  });

  it('renders work item on `/1` route', async () => {
    await createComponent('/1');

    expect(wrapper.findComponent(WorkItemsRoot).exists()).toBe(true);
  });

  it('does not render create work item page on `/new` route if `workItemsMvc2` feature flag is off', async () => {
    await createComponent('/new');

    expect(wrapper.findComponent(CreateWorkItem).exists()).toBe(false);
  });

  it('renders create work item page on `/new` route', async () => {
    window.gon.features.workItemsMvc2 = true;
    await createComponent('/new');

    expect(wrapper.findComponent(CreateWorkItem).exists()).toBe(true);
  });
});
