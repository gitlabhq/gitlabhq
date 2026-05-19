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
import { useLocalStorageSpy } from 'helpers/local_storage_helper';
import namespaceWorkItemTypesQuery from '~/work_items/graphql/namespace_work_item_types.query.graphql';
import getWorkItemsQuery from 'ee_else_ce/work_items/list/graphql/get_work_items_full.query.graphql';
import getWorkItemsSlimQuery from 'ee_else_ce/work_items/list/graphql/get_work_items_slim.query.graphql';
import getWorkItemsRestQuery from '~/work_items/list/graphql/get_work_items_rest.query.graphql';
import workItemsReorderMutation from '~/work_items/graphql/work_items_reorder.mutation.graphql';
import { scrollUp } from '~/lib/utils/scroll_utils';
import { getParameterByName } from '~/lib/utils/url_utility';
import IssuableBulkEditSidebar from '~/vue_shared/issuable/list/components/issuable_bulk_edit_sidebar.vue';
import PageSizeSelector from '~/vue_shared/components/page_size_selector.vue';
import IssuableItem from '~/vue_shared/issuable/list/components/issuable_item.vue';
import CreateWorkItemModal from '~/work_items/components/create_work_item_modal.vue';
import ListView from '~/work_items/list/list_view.vue';
import { WORK_ITEM_TYPE_NAME_TICKET } from '~/work_items/constants';
import { CREATED_DESC, UPDATED_DESC } from '~/work_items/list/constants';
import { STATUS_OPEN } from '~/issues/constants';
import { routes } from '~/work_items/router/routes';
import { isLoggedIn } from '~/lib/utils/common_utils';
import {
  workItemsQueryResponseCombined,
  workItemsWithSubChildQueryResponse,
  namespaceWorkItemTypesQueryResponse,
  workItemsQueryResponseNoLabels,
  workItemsQueryResponseNoAssignees,
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

const exampleQueryParams = {
  fullPath: 'full/path',
  includeDescendants: true,
  sort: CREATED_DESC,
  state: STATUS_OPEN,
  firstPageSize: 20,
};

/** @type {import('helpers/vue_test_utils_helper').ExtendedWrapper} */
let wrapper;
let router;

Vue.use(VueApollo);
Vue.use(VueRouter);

useLocalStorageSpy();

const namespaceQueryHandler = jest.fn().mockResolvedValue(namespaceWorkItemTypesQueryResponse);
const workItemsFullQueryHandler = jest.fn().mockResolvedValue(workItemsQueryResponseNoLabels);
const workItemsSlimQueryHandler = jest.fn().mockResolvedValue(workItemsQueryResponseNoAssignees);
const reorderMutationHandler = jest.fn().mockResolvedValue({
  data: {
    workItemsReorder: {
      workItem: { id: 'gid://gitlab/WorkItem/1', iid: '1', title: 'Test', __typename: 'WorkItem' },
      errors: [],
    },
  },
});

beforeEach(() => {
  workItemsFullQueryHandler.mockResolvedValue(workItemsQueryResponseCombined);
  workItemsSlimQueryHandler.mockResolvedValue(workItemsQueryResponseCombined);
});

const findBulkEditSidebarWrapper = () => wrapper.findComponent(IssuableBulkEditSidebar);
const findWorkItemListWrapper = () => wrapper.findByTestId('work-item-list-wrapper');
const findPaginationControls = () => wrapper.findComponent(GlKeysetPagination);
const findPageSizeSelector = () => wrapper.findComponent(PageSizeSelector);
const findIssuableItems = () => wrapper.findAllComponents(IssuableItem);
const findIssueCardStatistics = () => wrapper.findComponent(IssueCardStatistics);
const findIssueCardTimeInfo = () => wrapper.findComponent(IssueCardTimeInfo);
const findHealthStatus = () => wrapper.findComponent(HealthStatus);
const findCreateWorkItemModal = () => wrapper.findComponent(CreateWorkItemModal);
const findBulkEditStartButton = () => wrapper.findByTestId('bulk-edit-start-button');
const findBulkEditSidebar = () => wrapper.findComponent(WorkItemBulkEditSidebar);
const findChildItem1 = () => findIssuableItems().at(0);
const findChildItem2 = () => findIssuableItems().at(1);
const findSubChildIndicator = (item) => item.find('[data-testid="sub-child-work-item-indicator"]');
const findGlAlert = () => wrapper.findComponent(GlAlert);

const defaultQueryVariables = {
  fullPath: 'full/path',
  sort: CREATED_DESC,
  state: STATUS_OPEN,
};

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
    [getWorkItemsQuery, workItemsFullQueryHandler],
    [getWorkItemsSlimQuery, workItemsSlimQueryHandler],
    [workItemsReorderMutation, reorderMutationHandler],
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
      queryVariables: defaultQueryVariables,
      hasWorkItems: true,
      initialLoadWasFiltered: false,
      withTabs,
      showBulkEditSidebar: false,
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

it('renders loading icon while query is in flight', () => {
  mountComponent();

  // Before promises resolve, Apollo queries are loading
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

  it('does not show tree icon if not searched parent', async () => {
    workItemsSlimQueryHandler.mockResolvedValue(workItemsWithSubChildQueryResponse);
    workItemsFullQueryHandler.mockResolvedValue(workItemsWithSubChildQueryResponse);

    mountComponent();
    await waitForPromises();

    expect(findSubChildIndicator(findChildItem1()).exists()).toBe(false);
    expect(findSubChildIndicator(findChildItem2()).exists()).toBe(false);
  });

  it('shows tree icon based on a sub child of the searched parent', async () => {
    setWindowLocation('?parent_id=1');

    workItemsSlimQueryHandler.mockResolvedValue(workItemsWithSubChildQueryResponse);
    workItemsFullQueryHandler.mockResolvedValue(workItemsWithSubChildQueryResponse);

    mountComponent({
      props: {
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
      workItemsSlimQueryHandler.mockResolvedValue({
        data: {
          namespace: {
            ...workItemsQueryResponseCombined.data.namespace,
            workItems: {
              ...workItemsQueryResponseCombined.data.namespace.workItems,
              pageInfo: {
                ...pageInfo,
                startCursor: 'start',
                endCursor: 'end',
                __typename: 'PageInfo',
              },
            },
          },
        },
      });
      workItemsFullQueryHandler.mockResolvedValue({
        data: {
          namespace: {
            ...workItemsQueryResponseCombined.data.namespace,
            workItems: {
              ...workItemsQueryResponseCombined.data.namespace.workItems,
              pageInfo: {
                ...pageInfo,
                startCursor: 'start',
                endCursor: 'end',
                __typename: 'PageInfo',
              },
            },
          },
        },
      });

      mountComponent();
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
  `('when moving $description, calls the reorder mutation', async ({ oldIndex, newIndex }) => {
    mountComponent();
    await waitForPromises();

    await findWorkItemListWrapper().trigger('update', { oldIndex, newIndex });
    await waitForPromises();

    expect(reorderMutationHandler).toHaveBeenCalled();
    // Reorder is handled internally — no 'reorder' event is emitted
    expect(wrapper.emitted('reorder')).toBeUndefined();
  });
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

describe('slim and full queries', () => {
  beforeEach(() => {
    mountComponent({ props: { queryVariables: exampleQueryParams } });

    return waitForPromises();
  });

  it('calls the slim query as well as the full query', () => {
    expect(workItemsSlimQueryHandler).toHaveBeenCalled();
    expect(workItemsFullQueryHandler).toHaveBeenCalled();
  });
});

describe('when workItemRestApiFrontendUsers and workItemRestApi are enabled', () => {
  let restQueryHandler;

  beforeEach(async () => {
    restQueryHandler = jest.fn().mockResolvedValue({
      data: {
        namespace: {
          id: 'gid://gitlab/Group/3',
          __typename: 'Namespace',
          fullPath: 'full/path',
          name: 'Test',
          workItems: {
            __typename: 'WorkItemConnection',
            pageInfo: {
              hasNextPage: false,
              hasPreviousPage: false,
              startCursor: null,
              endCursor: null,
              __typename: 'PageInfo',
            },
            nodes: [
              {
                __typename: 'WorkItem',
                id: 'gid://gitlab/WorkItem/1',
                iid: '1',
                title: 'REST work item',
                state: 'OPEN',
              },
            ],
          },
        },
      },
    });

    mountComponent({
      additionalHandlers: [[getWorkItemsRestQuery, restQueryHandler]],
      provide: { glFeatures: { workItemRestApiFrontendUsers: true, workItemRestApi: true } },
      props: { queryVariables: exampleQueryParams },
    });

    await waitForPromises();
  });

  it('calls getWorkItemsRestQuery instead of getWorkItemsSlimQuery', () => {
    expect(restQueryHandler).toHaveBeenCalled();
    expect(workItemsSlimQueryHandler).not.toHaveBeenCalled();
  });

  describe('filtering and sorting', () => {
    it('applies filters', async () => {
      wrapper.setProps({
        queryVariables: { authorUsername: 'homer' },
      });
      await nextTick();
      expect(restQueryHandler).toHaveBeenCalledWith(
        expect.objectContaining({ authorUsername: 'homer' }),
      );
    });

    it('applies sort', async () => {
      wrapper.setProps({
        queryVariables: { sort: UPDATED_DESC },
      });
      await waitForPromises();
      expect(restQueryHandler).toHaveBeenCalledWith(
        expect.objectContaining({ sort: UPDATED_DESC }),
      );
    });
  });
});
