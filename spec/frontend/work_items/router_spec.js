import { mount } from '@vue/test-utils';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createMockApollo from 'helpers/mock_apollo_helper';
import { useLocalStorageSpy } from 'helpers/local_storage_helper';
import { setHTMLFixture, resetHTMLFixture } from 'helpers/fixtures';
import {
  currentUserResponse,
  workItemByIidResponseFactory,
  allowedChildrenTypesResponse,
  mockProjectPermissionsQueryResponse,
  allowedParentTypesResponse,
} from 'jest/work_items/mock_data';
import currentUserQuery from '~/graphql_shared/queries/current_user.query.graphql';
import App from '~/work_items/components/app.vue';
import workItemByIidQuery from '~/work_items/graphql/work_item_by_iid.query.graphql';
import CreateWorkItem from '~/work_items/pages/create_work_item.vue';
import { WORK_ITEM_BASE_ROUTE_MAP } from '~/work_items/constants';
import WorkItemsRoot from '~/work_items/pages/work_item_root.vue';
import { createRouter } from '~/work_items/router';
import workItemUpdatedSubscription from '~/work_items/graphql/work_item_updated.subscription.graphql';
import getAllowedWorkItemChildTypes from '~/work_items/graphql/work_item_allowed_children.query.graphql';
import workspacePermissionsQuery from '~/work_items/graphql/workspace_permissions.query.graphql';
import getAllowedWorkItemParentTypes from '~/work_items/graphql/work_item_allowed_parent_types.query.graphql';

jest.mock('~/behaviors/markdown/render_gfm');

describe('Work items router', () => {
  useLocalStorageSpy();
  let wrapper;

  Vue.use(VueApollo);

  const workItemTypes = Object.keys(WORK_ITEM_BASE_ROUTE_MAP);
  const workItemQueryHandler = jest
    .fn()
    .mockResolvedValue(workItemByIidResponseFactory({ hierarchyWidgetPresent: false }));
  const currentUserQueryHandler = jest.fn().mockResolvedValue(currentUserResponse);
  const workItemUpdatedSubscriptionHandler = jest
    .fn()
    .mockResolvedValue({ data: { workItemUpdated: null } });
  const allowedChildrenTypesHandler = jest.fn().mockResolvedValue(allowedChildrenTypesResponse);
  const workspacePermissionsHandler = jest
    .fn()
    .mockResolvedValue(mockProjectPermissionsQueryResponse());
  const allowedParentTypesHandler = jest.fn().mockResolvedValue(allowedParentTypesResponse);

  const findCreateWorkItem = () => wrapper.findComponent(CreateWorkItem);

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
      [workspacePermissionsQuery, workspacePermissionsHandler],
      [getAllowedWorkItemParentTypes, allowedParentTypesHandler],
    ];

    wrapper = mount(App, {
      apolloProvider: createMockApollo(handlers),
      router,
      provide: {
        canAdminLabel: true,
        duoRemoteFlowsAvailability: false,
        fullPath: 'full-path',
        groupPath: '',
        isGroup: false,
        issuesListPath: 'full-path/-/issues',
        hasDesignManagementFeature: false,
        hasIssueWeightsFeature: false,
        hasIterationsFeature: false,
        hasOkrsFeature: false,
        hasSubepicsFeature: false,
        hasLinkedItemsEpicsFeature: false,
        hasIssuableHealthStatusFeature: false,
        labelsManagePath: 'test-project-path/labels',
        reportAbusePath: '/report/abuse/path',
        newTrialPath: '',
      },
      propsData: {
        rootPageFullPath: '/',
      },
      stubs: {
        WorkItemWeight: true,
        WorkItemIteration: true,
        WorkItemHealthStatus: true,
        WorkItemNotes: true,
        WorkItemAwardEmoji: true,
        WorkItemTimeTracking: true,
        WorkItemAncestors: true,
        WorkItemCreateBranchMergeRequestModal: true,
        WorkItemDevelopment: true,
        WorkItemChangeTypeModal: true,
        WorkItemErrorTracking: true,
        WorkItemMetadataProvider: true,
      },
    });
  };

  beforeEach(() => {
    setHTMLFixture(`<div class="params-issue-type">issue</div>`);
  });

  afterEach(() => {
    window.location.hash = '';
    resetHTMLFixture();
    localStorage.clear();
  });

  it('includes relative_url_root', () => {
    gon.relative_url_root = '/my-org';
    const router = createRouter({ fullPath: '/work_item' });

    // options.history only exists in Vue 3 router
    const basePath = router.options.history?.base || router.options.base;

    expect(basePath).toBe('/my-org/work_item/-');
  });

  it('includes groups in path for groups', () => {
    const router = createRouter({ fullPath: '/work_item', workspaceType: 'group' });

    // options.history only exists in Vue 3 router
    const basePath = router.options.history?.base || router.options.base;

    expect(basePath).toBe('/groups/work_item/-');
  });

  it(`renders create work item page on /issues/new route with 'type' param set to 'ISSUE'`, async () => {
    await createComponent(`/issues/new?type=ISSUE`);

    expect(findCreateWorkItem().exists()).toBe(true);
    expect(findCreateWorkItem().props('workItemTypeEnum')).toBe('ISSUE');
  });

  it(`renders create work item page on /issues/new route with 'issue[issue_type]' param set to 'ISSUE'`, async () => {
    await createComponent(`/issues/new?issue%5Bissue_type%5D%3DISSUE`);

    expect(findCreateWorkItem().exists()).toBe(true);
    expect(findCreateWorkItem().props('workItemTypeEnum')).toBe('ISSUE');
  });

  it(`renders create work item page on /issues/new route work item type set via localStorage draft`, async () => {
    localStorage.setItem(
      // full-path in router is set to `/work_item
      'autosave/new-/work_item-new-route-widgets-draft',
      JSON.stringify({ TYPE: { name: 'Task' } }),
    );
    await createComponent(`/issues/new`);

    expect(findCreateWorkItem().exists()).toBe(true);
    expect(findCreateWorkItem().props('workItemTypeEnum')).toBe('TASK');
  });

  describe.each(workItemTypes)('Create Work Item for type: %s', (type) => {
    it(`renders create work item page on /${type}/new route`, async () => {
      await createComponent(`/${type}/new`);

      expect(findCreateWorkItem().exists()).toBe(true);
    });
  });

  describe.each(workItemTypes)('Display Work Item for type: %s', (type) => {
    it(`renders work item page on /${type}/1 route`, async () => {
      await createComponent(`/${type}/1`);

      expect(wrapper.findComponent(WorkItemsRoot).exists()).toBe(true);
    });
  });
});
