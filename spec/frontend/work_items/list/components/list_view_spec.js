import { GlLoadingIcon, GlAlert, GlKeysetPagination } from '@gitlab/ui';
import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import VueRouter from 'vue-router';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import IssueCardStatistics from 'ee_else_ce/work_items/list/components/issue_card_statistics.vue';
import IssueCardTimeInfo from 'ee_else_ce/work_items/list/components/issue_card_time_info.vue';
import WorkItemBulkEditSidebar from '~/work_items/list/components/work_item_bulk_edit_sidebar.vue';
import HealthStatus from '~/work_items/list/components/health_status.vue';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import setWindowLocation from 'helpers/set_window_location_helper';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import { useLocalStorageSpy } from 'helpers/local_storage_helper';
import namespaceWorkItemTypesQuery from '~/work_items/graphql/namespace_work_item_types.query.graphql';
import { scrollUp } from '~/lib/utils/scroll_utils';
import { getParameterByName, removeParams, updateHistory } from '~/lib/utils/url_utility';
import IssuableBulkEditSidebar from '~/vue_shared/issuable/list/components/issuable_bulk_edit_sidebar.vue';
import PageSizeSelector from '~/vue_shared/components/page_size_selector.vue';
import IssuableItem from '~/vue_shared/issuable/list/components/issuable_item.vue';
import CreateWorkItemModal from '~/work_items/components/create_work_item_modal.vue';
import ListView from '~/work_items/list/list_view.vue';
import WorkItemDrawer from '~/work_items/components/work_item_drawer.vue';
import {
  DETAIL_VIEW_QUERY_PARAM_NAME,
  STATE_CLOSED,
  WORK_ITEM_TYPE_NAME_EPIC,
  WORK_ITEM_TYPE_NAME_ISSUE,
  WORK_ITEM_TYPE_NAME_TICKET,
} from '~/work_items/constants';
import { CREATED_DESC } from '~/work_items/list/constants';
import { STATUS_OPEN } from '~/issues/constants';
import { routes } from '~/work_items/router/routes';
import { isLoggedIn } from '~/lib/utils/common_utils';
import {
  workItemsQueryResponseCombined,
  workItemsWithSubChildQueryResponse,
  namespaceWorkItemTypesQueryResponse,
} from '../../mock_data';

jest.mock('~/lib/utils/scroll_utils', () => ({ scrollUp: jest.fn() }));
jest.mock('~/sentry/sentry_browser_wrapper');
jest.mock('~/lib/utils/url_utility');
jest.mock('~/alert');
jest.mock('~/lib/utils/common_utils');
jest.mock('~/lib/utils/confirm_via_gl_modal/confirm_via_gl_modal', () => ({
  confirmAction: jest.fn().mockResolvedValue(true),
}));
jest.mock('ee_else_ce/work_items/list/utils', () => ({
  ...jest.requireActual('ee_else_ce/work_items/list/utils'),
  saveSavedView: jest.fn(),
}));

const showToast = jest.fn();

const RELEASES_ENDPOINT = '/test/project/-/releases.json';

/** @type {import('helpers/vue_test_utils_helper').ExtendedWrapper} */
let wrapper;
let router;

Vue.use(VueApollo);
Vue.use(VueRouter);

useLocalStorageSpy();

const namespaceQueryHandler = jest.fn().mockResolvedValue(namespaceWorkItemTypesQueryResponse);

const findBulkEditSidebarWrapper = () => wrapper.findComponent(IssuableBulkEditSidebar);
const findWorkItemListWrapper = () => wrapper.findByTestId('work-item-list-wrapper');
const findPaginationControls = () => wrapper.findComponent(GlKeysetPagination);
const findPageSizeSelector = () => wrapper.findComponent(PageSizeSelector);
const findIssuableItems = () => wrapper.findAllComponents(IssuableItem);
const findIssueCardStatistics = () => wrapper.findComponent(IssueCardStatistics);
const findIssueCardTimeInfo = () => wrapper.findComponent(IssueCardTimeInfo);
const findHealthStatus = () => wrapper.findComponent(HealthStatus);
const findDrawer = () => wrapper.findComponent(WorkItemDrawer);
const findCreateWorkItemModal = () => wrapper.findComponent(CreateWorkItemModal);
const findBulkEditStartButton = () => wrapper.findByTestId('bulk-edit-start-button');
const findBulkEditSidebar = () => wrapper.findComponent(WorkItemBulkEditSidebar);
const findChildItem1 = () => findIssuableItems().at(0);
const findChildItem2 = () => findIssuableItems().at(1);
const findSubChildIndicator = (item) => item.find('[data-testid="sub-child-work-item-indicator"]');
const findGlAlert = () => wrapper.findComponent(GlAlert);

const mountComponent = ({
  provide = {},
  workItemFeaturesField = false,
  props = {},
  additionalHandlers = [],
  canReadCrmOrganization = true,
  canReadCrmContact = true,
  isIssueRepositioningDisabled = false,
  hasProjects = true,
  stubs = {},
  isLoggedInValue = true,
  withTabs = false,
} = {}) => {
  window.gon = {
    ...window.gon,
    features: {
      workItemsClientSideBoards: false,
    },
  };

  router = new VueRouter({
    mode: 'history',
    routes: [
      { name: 'base', path: '/', component: ListView },
      ...routes({ fullPath: '/work_item' }),
    ],
  });

  isLoggedIn.mockReturnValue(isLoggedInValue);

  const apolloProvider = createMockApollo([
    [namespaceWorkItemTypesQuery, namespaceQueryHandler],
    ...additionalHandlers,
  ]);

  wrapper = shallowMountExtended(ListView, {
    router,
    apolloProvider,
    provide: {
      glFeatures: {
        okrsMvc: true,
        workItemFeaturesField,
      },
      canReadCrmOrganization,
      canReadCrmContact,
      autocompleteAwardEmojisPath: 'autocomplete/award/emojis/path',
      canAdminIssue: true,
      canBulkAdminEpic: true,
      canCreateProjects: true,
      hasBlockedIssuesFeature: false,
      hasEpicsFeature: false,
      hasGroupBulkEditFeature: true,
      hasIssuableHealthStatusFeature: false,
      hasIssueDateFilterFeature: false,
      hasIssueWeightsFeature: false,
      hasOkrsFeature: false,
      hasQualityManagementFeature: false,
      hasCustomFieldsFeature: false,
      hasStatusFeature: false,
      isGroup: true,
      isServiceDeskSupported: false,
      showNewWorkItem: true,
      workItemType: null,
      canCreateWorkItem: false,
      newWorkItemEmailAddress: null,
      emailsHelpPagePath: '/help/development/emails.md#email-namespace',
      markdownHelpPath: '/help/user/markdown.md',
      quickActionsHelpPath: '/help/user/project/quick_actions.md',
      releasesPath: RELEASES_ENDPOINT,
      metadataLoading: false,
      email: '',
      hasAnyWorkItems: false,
      projectImportJiraPath: '/project/import/jira',
      isGroupIssuesList: false,
      groupId: 'gid://gitlab/Group/1',
      isProject: false,
      exportCsvPath: '/export/csv',
      canEdit: true,
      canImportWorkItems: true,
      isIssueRepositioningDisabled,
      hasProjects,
      newIssuePath: '',
      subscribedSavedViewLimit: 5,
      canCreateSavedView: true,
      namespaceName: 'Test',
      ...provide,
    },
    propsData: {
      rootPageFullPath: 'full/path',
      workItems: workItemsQueryResponseCombined.data.namespace.workItems.nodes,
      hasWorkItems: true,
      workItemTypes: namespaceWorkItemTypesQueryResponse.data.namespace.workItemTypes.nodes,
      isInitialLoadComplete: true,
      initialLoadWasFiltered: false,
      detailLoading: false,
      isLoading: false,
      withTabs,
      showBulkEditSidebar: false,
      pageInfo: {
        hasNextPage: true,
        hasPreviousPage: false,
        startCursor: 'startCursor',
        endCursor: 'endCursor',
      },
      sortKey: CREATED_DESC,
      isSortKeyInitialized: true,
      state: STATUS_OPEN,
      ...props,
    },
    stubs: {
      WorkItemBulkEditSidebar: true,
      ...stubs,
    },
    mocks: {
      $toast: {
        show: showToast,
      },
    },
  });
};

const mountComponentWithShowParam = async (issue, mountOptions = {}) => {
  const showParams = {
    id: getIdFromGraphQLId(issue.id),
    iid: issue.iid,
    full_path: issue.namespace.fullPath,
  };
  const show = btoa(JSON.stringify(showParams));
  setWindowLocation(`?${DETAIL_VIEW_QUERY_PARAM_NAME}=${show}`);
  getParameterByName.mockReturnValue(show);

  const { provide = {}, ...restOptions } = mountOptions;
  mountComponent({
    provide: {
      workItemType: WORK_ITEM_TYPE_NAME_ISSUE,
      ...provide,
    },
    ...restOptions,
  });
  await waitForPromises();
  await nextTick();
};

it('renders loading icon when isInitialLoadComplete prop is false', () => {
  mountComponent({ props: { isInitialLoadComplete: false } });

  expect(wrapper.findComponent(GlLoadingIcon).exists()).toBe(true);
});

describe('when work items are fetched', () => {
  beforeEach(async () => {
    mountComponent();
    await waitForPromises();
  });

  it('renders IssueCardStatistics component', () => {
    expect(findIssueCardStatistics().exists()).toBe(true);
  });

  it('renders IssueCardTimeInfo component', () => {
    expect(findIssueCardTimeInfo().exists()).toBe(true);
  });

  it('renders IssueHealthStatus component', () => {
    expect(findHealthStatus().exists()).toBe(true);
  });

  it('renders work items', () => {
    expect(findIssuableItems()).toHaveLength(
      workItemsQueryResponseCombined.data.namespace.workItems.nodes.length,
    );
  });

  it('calls `getParameterByName` to get the `show` param', () => {
    expect(getParameterByName).toHaveBeenCalledWith(DETAIL_VIEW_QUERY_PARAM_NAME);
  });

  it('does not show tree icon if not searched parent', async () => {
    mountComponent({
      props: { workItems: workItemsWithSubChildQueryResponse.data.namespace.workItems.nodes },
    });

    await waitForPromises();

    expect(findSubChildIndicator(findChildItem1()).exists()).toBe(false);
    expect(findSubChildIndicator(findChildItem2()).exists()).toBe(false);
  });

  it('shows tree icon based on a sub child of the searched parent', async () => {
    setWindowLocation('?parent_id=1');

    mountComponent({
      props: {
        workItems: workItemsWithSubChildQueryResponse.data.namespace.workItems.nodes,
        apiFilterParams: {
          hierarchyFilters: {
            parentIds: ['gid://gitlab/WorkItem/1'],
          },
        },
      },
    });

    await waitForPromises();

    expect(findSubChildIndicator(findChildItem1()).exists()).toBe(true);
    expect(findSubChildIndicator(findChildItem2()).exists()).toBe(false);
  });

  it('does not display error alert when there is no error', async () => {
    mountComponent();
    await waitForPromises();
    expect(findGlAlert().exists()).toBe(false);
  });
});

describe('pagination controls', () => {
  describe.each`
    description                                                | pageInfo                                          | exists
    ${'when hasNextPage=true and hasPreviousPage=true'}        | ${{ hasNextPage: true, hasPreviousPage: true }}   | ${true}
    ${'when hasNextPage=true'}                                 | ${{ hasNextPage: true, hasPreviousPage: false }}  | ${true}
    ${'when hasPreviousPage=true'}                             | ${{ hasNextPage: false, hasPreviousPage: true }}  | ${true}
    ${'when neither hasNextPage nor hasPreviousPage are true'} | ${{ hasNextPage: false, hasPreviousPage: false }} | ${false}
  `('$description', ({ pageInfo, exists }) => {
    it(`${exists ? 'renders' : 'does not render'} pagination controls`, async () => {
      mountComponent({
        props: {
          pageInfo,
        },
      });
      await waitForPromises();

      expect(findPaginationControls().exists()).toBe(exists);
    });
  });
});

describe('events', () => {
  describe.each`
    event     | params
    ${'next'} | ${{ afterCursor: 'endCursor', firstPageSize: 20 }}
    ${'prev'} | ${{ beforeCursor: 'startCursor', lastPageSize: 20 }}
  `('when "$event" event is emitted by PaginationControls', ({ event, params }) => {
    beforeEach(async () => {
      getParameterByName.mockImplementation((args) =>
        jest.requireActual('~/lib/utils/url_utility').getParameterByName(args),
      );
      mountComponent();
      await waitForPromises();

      findPaginationControls().vm.$emit(event);
      await nextTick();
    });

    it('scrolls to the top', () => {
      expect(scrollUp).toHaveBeenCalled();
    });

    it('emits the set-page-params event', () => {
      expect(wrapper.emitted('set-page-params').at(-1)[0]).toMatchObject(params);
    });
  });

  describe('when "page-size-change" event is emitted by PageSizeSelector', () => {
    it('emits the set-page-size event', async () => {
      mountComponent();
      await waitForPromises();

      findPageSizeSelector().vm.$emit('input', 50);
      await nextTick();

      expect(wrapper.emitted('set-page-size').at(-1)[0]).toBe(50);
    });
  });
});

describe('display settings', () => {
  it('passes hiddenMetadataKeys to IssuableItems', async () => {
    mountComponent({
      props: {
        displaySettings: {
          commonPreferences: {
            shouldOpenItemsInSidePanel: true,
          },
          namespacePreferences: {
            hiddenMetadataKeys: ['labels', 'milestone'],
          },
        },
      },
    });
    await waitForPromises();

    expect(findIssuableItems().at(1).props('hiddenMetadataKeys')).toEqual(['labels', 'milestone']);
  });

  it('passes hiddenMetadataKeys to IssueCardTimeInfo', async () => {
    mountComponent({
      props: {
        displaySettings: {
          commonPreferences: {
            shouldOpenItemsInSidePanel: true,
          },
          namespacePreferences: {
            hiddenMetadataKeys: ['dates', 'milestone'],
          },
        },
      },
    });
    await waitForPromises();

    expect(findIssueCardTimeInfo().props('hiddenMetadataKeys')).toEqual(['dates', 'milestone']);
  });
});

describe('work item drawer', () => {
  describe('when rendering issues list', () => {
    it.each`
      message              | shouldOpenItemsInSidePanel | drawerExists
      ${'is rendered'}     | ${true}                    | ${true}
      ${'is not rendered'} | ${false}                   | ${false}
    `(
      '$message when shouldOpenItemsInSidePanel is $shouldOpenItemsInSidePanel',
      async ({ shouldOpenItemsInSidePanel, drawerExists }) => {
        mountComponent({
          props: {
            displaySettings: {
              commonPreferences: {
                shouldOpenItemsInSidePanel,
              },
            },
          },
        });

        await waitForPromises();

        expect(findDrawer().exists()).toBe(drawerExists);
      },
    );

    describe('selecting issues', () => {
      const issue = workItemsQueryResponseCombined.data.namespace.workItems.nodes[0];
      const payload = {
        iid: issue.iid,
        webUrl: issue.webUrl,
        fullPath: issue.namespace.fullPath,
      };

      beforeEach(async () => {
        mountComponent();
        await waitForPromises();

        findChildItem1().vm.$emit('select-issuable', payload);

        await nextTick();
      });

      it('opens drawer when work item is selected', () => {
        expect(findDrawer().props('open')).toBe(true);
        expect(findDrawer().props('activeItem')).toEqual(payload);
      });

      it('closes drawer when work item is clicked again', async () => {
        findChildItem1().vm.$emit('select-issuable', payload);
        await nextTick();

        expect(findDrawer().props('open')).toBe(false);
        expect(findDrawer().props('activeItem')).toBeNull();
      });

      const checkThatDrawerPropsAreEmpty = () => {
        expect(findDrawer().props('activeItem')).toBeNull();
        expect(findDrawer().props('open')).toBe(false);
      };

      it('resets the selected item when the drawer is closed', async () => {
        findDrawer().vm.$emit('close');

        await nextTick();

        checkThatDrawerPropsAreEmpty();
      });

      it('emits the refetch event to refetch counts and resets when work item is deleted', async () => {
        expect(wrapper.emitted('refetch-data')).toBeUndefined();

        findDrawer().vm.$emit('work-item-deleted');

        await nextTick();

        checkThatDrawerPropsAreEmpty();

        expect(wrapper.emitted('refetch-data')).toHaveLength(1);
      });

      it('emits the refetch event to refetch counts when the selected work item is closed', async () => {
        expect(wrapper.emitted('refetch-data')).toBeUndefined();

        // component displays open work items by default
        findDrawer().vm.$emit('work-item-updated', {
          state: STATE_CLOSED,
        });

        await nextTick();

        expect(wrapper.emitted('refetch-data')).toHaveLength(1);
      });
    });
  });

  describe('when rendering epics list', () => {
    beforeEach(async () => {
      mountComponent({
        provide: {
          workItemType: WORK_ITEM_TYPE_NAME_EPIC,
        },
      });
      await waitForPromises();
    });

    it('uses work item drawer', () => {
      expect(findDrawer().exists()).toBe(true);
    });
  });

  describe('When the `show` parameter matches an item in the list', () => {
    it('displays the item in the drawer', async () => {
      const issue = workItemsQueryResponseCombined.data.namespace.workItems.nodes[0];
      await mountComponentWithShowParam(issue);

      expect(findDrawer().props('open')).toBe(true);
      expect(findDrawer().props('activeItem')).toMatchObject(issue);
    });
  });

  describe('When the `show` parameter does not match an item in the list', () => {
    beforeEach(async () => {
      const showParams = { id: 9999, iid: '9999', full_path: 'does/not/match' };
      const show = btoa(JSON.stringify(showParams));
      setWindowLocation(`?${DETAIL_VIEW_QUERY_PARAM_NAME}=${show}`);
      getParameterByName.mockReturnValue(show);
      mountComponent({
        provide: {
          workItemType: WORK_ITEM_TYPE_NAME_ISSUE,
        },
      });
      await waitForPromises();
    });
    it('calls `updateHistory', () => {
      expect(updateHistory).toHaveBeenCalled();
    });
    it('calls `removeParams` to remove the `show` param', () => {
      expect(removeParams).toHaveBeenCalledWith([DETAIL_VIEW_QUERY_PARAM_NAME]);
    });
  });

  describe('when window `popstate` event is triggered', () => {
    it('updates the drawer with the new item if there is a `show` param', async () => {
      const issue = workItemsQueryResponseCombined.data.namespace.workItems.nodes[0];
      const nextIssue = workItemsQueryResponseCombined.data.namespace.workItems.nodes[1];
      await mountComponentWithShowParam(issue);

      expect(findDrawer().props('open')).toBe(true);
      expect(findDrawer().props('activeItem')).toMatchObject(issue);

      const showParams = {
        id: getIdFromGraphQLId(nextIssue.id),
        iid: nextIssue.iid,
        full_path: nextIssue.namespace.fullPath,
      };
      const show = btoa(JSON.stringify(showParams));
      setWindowLocation(`?${DETAIL_VIEW_QUERY_PARAM_NAME}=${show}`);

      window.dispatchEvent(new Event('popstate'));
      await waitForPromises();

      expect(findDrawer().props('open')).toBe(true);
      expect(findDrawer().props('activeItem')).toMatchObject(issue);
    });
  });
});

describe('when bulk editing', () => {
  it('closes the bulk edit sidebar when the "success" event is emitted', async () => {
    mountComponent({ props: { showBulkEditSidebar: true } });
    await waitForPromises();

    expect(findBulkEditSidebarWrapper().props('expanded')).toBe(true);

    findBulkEditSidebar().vm.$emit('success');
    await nextTick();

    expect(wrapper.emitted('toggle-bulk-edit-sidebar')[0][0]).toBe(false);
  });

  it('does not close the bulk edit sidebar when no "success" event is emitted', async () => {
    mountComponent({ props: { showBulkEditSidebar: true } });
    await waitForPromises();

    expect(findBulkEditSidebarWrapper().props('expanded')).toBe(true);

    findBulkEditSidebar().vm.$emit('finish');
    await nextTick();

    expect(wrapper.emitted('toggle-bulk-edit-sidebar')).toBeUndefined();
  });

  it('creates a toast when the success event includes a toast message', async () => {
    mountComponent({ props: { showBulkEditSidebar: true } });
    await waitForPromises();

    expect(findBulkEditSidebarWrapper().props('expanded')).toBe(true);

    findBulkEditSidebar().vm.$emit('success', { toastMessage: 'hello!' });
    await nextTick();

    expect(showToast).toHaveBeenCalledWith('hello!');
  });
});

describe('when "update" event is emitted by VueSortable', () => {
  it.each`
    description                        | oldIndex | newIndex
    ${'first item to second position'} | ${0}     | ${1}
    ${'second item to first position'} | ${1}     | ${0}
  `('when moving $description', async ({ oldIndex, newIndex }) => {
    mountComponent();
    await waitForPromises();

    await findWorkItemListWrapper().trigger('update', { oldIndex, newIndex });
    await nextTick();

    expect(wrapper.emitted('reorder')).toEqual([[{ oldIndex, newIndex }]]);
  });
});

it('closes the drawer if there is no `show` param', async () => {
  const issue = workItemsQueryResponseCombined.data.namespace.workItems.nodes[0];
  await mountComponentWithShowParam(issue, {
    queryHandler: jest.fn().mockResolvedValue(workItemsQueryResponseCombined),
  });
  await waitForPromises();
  expect(findDrawer().props('open')).toBe(true);
  expect(findDrawer().props('activeItem')).toMatchObject({
    id: issue.id,
    iid: issue.iid,
  });

  setWindowLocation('?');
  getParameterByName.mockReturnValue(null);
  window.dispatchEvent(new Event('popstate'));

  await waitForPromises();
  expect(findDrawer().props('open')).toBe(false);
});

describe('when service desk list', () => {
  describe('nav actions', () => {
    it('does not render the bulk edit button, create work item modal, or actions dropdown', async () => {
      mountComponent({
        provide: { isServiceDeskSupported: true, workItemType: WORK_ITEM_TYPE_NAME_TICKET },
      });
      await waitForPromises();

      expect(findBulkEditStartButton().exists()).toBe(false);
      expect(findCreateWorkItemModal().exists()).toBe(false);
    });
  });
});
