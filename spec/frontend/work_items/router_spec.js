import { mount } from '@vue/test-utils';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createMockApollo from 'helpers/mock_apollo_helper';
import {
  currentUserResponse,
  workItemByIidResponseFactory,
  allowedChildrenTypesResponse,
} from 'jest/work_items/mock_data';
import currentUserQuery from '~/graphql_shared/queries/current_user.query.graphql';
import App from '~/work_items/components/app.vue';
import workItemByIidQuery from '~/work_items/graphql/work_item_by_iid.query.graphql';
import CreateWorkItem from '~/work_items/pages/create_work_item.vue';
import WorkItemsRoot from '~/work_items/pages/work_item_root.vue';
import { createRouter } from '~/work_items/router';
import workItemUpdatedSubscription from '~/work_items/graphql/work_item_updated.subscription.graphql';
import getAllowedWorkItemChildTypes from '~/work_items/graphql/work_item_allowed_children.query.graphql';

jest.mock('~/behaviors/markdown/render_gfm');

describe('Work items router', () => {
  let wrapper;

  Vue.use(VueApollo);

  const workItemQueryHandler = jest
    .fn()
    .mockResolvedValue(workItemByIidResponseFactory({ hierarchyWidgetPresent: false }));
  const currentUserQueryHandler = jest.fn().mockResolvedValue(currentUserResponse);
  const workItemUpdatedSubscriptionHandler = jest
    .fn()
    .mockResolvedValue({ data: { workItemUpdated: null } });
  const allowedChildrenTypesHandler = jest.fn().mockResolvedValue(allowedChildrenTypesResponse);

  const createComponent = async (routeArg) => {
    const router = createRouter({ fullPath: '/work_item' });
    if (routeArg !== undefined) {
      await router.push(routeArg);
    }

    const handlers = [
      [workItemByIidQuery, workItemQueryHandler],
      [currentUserQuery, currentUserQueryHandler],
      [workItemUpdatedSubscription, workItemUpdatedSubscriptionHandler],
      [getAllowedWorkItemChildTypes, allowedChildrenTypesHandler],
    ];

    wrapper = mount(App, {
      apolloProvider: createMockApollo(handlers),
      router,
      provide: {
        canAdminLabel: true,
        fullPath: 'full-path',
        groupPath: '',
        isGroup: false,
        issuesListPath: 'full-path/-/issues',
        hasIssueWeightsFeature: false,
        hasIterationsFeature: false,
        hasOkrsFeature: false,
        hasSubepicsFeature: false,
        hasIssuableHealthStatusFeature: false,
        labelsManagePath: 'test-project-path/labels',
        reportAbusePath: '/report/abuse/path',
      },
      stubs: {
        WorkItemWeight: true,
        WorkItemIteration: true,
        WorkItemHealthStatus: true,
        WorkItemNotes: true,
        WorkItemAwardEmoji: true,
        WorkItemTimeTracking: true,
        WorkItemAncestors: true,
      },
    });
  };

  beforeEach(() => {
    window.gon = {
      features: {
        workItemsAlpha: false,
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

  it('does not render create work item page on `/new` route if `workItemsAlpha` feature flag is off', async () => {
    await createComponent('/new');

    expect(wrapper.findComponent(CreateWorkItem).exists()).toBe(false);
  });

  it('renders create work item page on `/new` route', async () => {
    window.gon.features.workItemsAlpha = true;
    await createComponent('/new');

    expect(wrapper.findComponent(CreateWorkItem).exists()).toBe(true);
  });

  it('includes relative_url_root', () => {
    gon.relative_url_root = '/my-org';
    const router = createRouter({ fullPath: '/work_item' });

    expect(router.options.base).toBe('/my-org/work_item/-/work_items');
  });

  it('includes groups in path for groups', () => {
    const router = createRouter({ fullPath: '/work_item', workspaceType: 'group' });

    expect(router.options.base).toBe('/groups/work_item/-/work_items');
  });

  it('includes workItemType if provided', () => {
    const router = createRouter({ fullPath: '/work_item', workItemType: 'epics' });

    expect(router.options.base).toBe('/work_item/-/epics');
  });
});
