import { GlButton, GlLoadingIcon, GlSkeletonLoader } from '@gitlab/ui';
import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { stubComponent } from 'helpers/stub_component';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import getWorkItemsQuery from 'ee_else_ce/work_items/list/graphql/get_work_items_full.query.graphql';
import getWorkItemsSlimQuery from 'ee_else_ce/work_items/list/graphql/get_work_items_slim.query.graphql';
import getWorkItemsRestQuery from 'ee_else_ce/work_items/list/graphql/get_work_items_rest.query.graphql';
import { CREATED_DESC } from '~/work_items/list/constants';
import { STATUS_OPEN } from '~/issues/constants';
import {
  DETAIL_VIEW_QUERY_PARAM_NAME,
  METADATA_KEYS,
  WORK_ITEM_TYPE_NAME_EPIC,
} from '~/work_items/constants';
import { removeParams, updateHistory } from '~/lib/utils/url_utility';
import setWindowLocation from 'helpers/set_window_location_helper';
import { DEFAULT_SKELETON_COUNT } from '~/vue_shared/issuable/list/constants';
import IssuableBulkEditSidebar from '~/vue_shared/issuable/list/components/issuable_bulk_edit_sidebar.vue';
import WorkItemBulkEditSidebar from '~/work_items/list/components/work_item_bulk_edit_sidebar.vue';
import TableView from '~/work_items/table/table_view.vue';
import WorkItemTableRow from '~/work_items/table/components/work_item_table_row.vue';
import {
  buildBoardWorkItemsResponse,
  buildBoardRestWorkItemsResponse,
  buildWorkItemNode,
} from '../board/mock_data';

jest.mock('~/sentry/sentry_browser_wrapper');
jest.mock('~/lib/utils/url_utility', () => ({
  ...jest.requireActual('~/lib/utils/url_utility'),
  updateHistory: jest.fn(),
  removeParams: jest.fn(),
}));

Vue.use(VueApollo);

const showToast = jest.fn();

describe('TableView', () => {
  let wrapper;

  const workItems = [buildWorkItemNode(1), buildWorkItemNode(2)];
  const defaultQueryVariables = { fullPath: 'group', sort: CREATED_DESC, state: STATUS_OPEN };

  const workItemsResponse = buildBoardWorkItemsResponse(workItems);
  let slimQueryHandler;
  let fullQueryHandler;
  let restQueryHandler;

  const findLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);
  const findTable = () => wrapper.findByTestId('work-item-table');
  const findColumnHeaders = () => wrapper.findAll('thead th');
  const findColumnHeaderLabels = () => findColumnHeaders().wrappers.map((header) => header.text());
  const findRows = () => wrapper.findAllComponents(WorkItemTableRow);
  const findSkeletonLoaders = () => wrapper.findAllComponents(GlSkeletonLoader);
  const findSkeletonRows = () => wrapper.findAll('tbody tr');
  const findBulkEditSidebar = () => wrapper.findComponent(IssuableBulkEditSidebar);
  const findBulkEditForm = () => wrapper.findComponent(WorkItemBulkEditSidebar);
  const findUpdateSelectedButton = () =>
    wrapper
      .findAllComponents(GlButton)
      .wrappers.find((button) => button.text() === 'Update selected');
  const findCancelButton = () =>
    wrapper.findAllComponents(GlButton).wrappers.find((button) => button.text() === 'Cancel');

  const createComponent = ({
    props = {},
    provide = {},
    glFeatures = {},
    slots = {},
    failQueries = false,
  } = {}) => {
    const handler = (response) =>
      failQueries
        ? jest.fn().mockRejectedValue(new Error('oh no'))
        : jest.fn().mockResolvedValue(response);

    slimQueryHandler = handler(workItemsResponse);
    fullQueryHandler = handler(workItemsResponse);
    restQueryHandler = handler(buildBoardRestWorkItemsResponse(workItems));

    wrapper = shallowMountExtended(TableView, {
      apolloProvider: createMockApollo([
        [getWorkItemsQuery, fullQueryHandler],
        [getWorkItemsSlimQuery, slimQueryHandler],
        [getWorkItemsRestQuery, restQueryHandler],
      ]),
      provide: {
        glFeatures,
        hasIssuableHealthStatusFeature: false,
        hasIssueWeightsFeature: false,
        hasIterationsFeature: false,
        hasStatusFeature: false,
        isGroup: false,
        workItemType: null,
        ...provide,
      },
      propsData: {
        rootPageFullPath: 'group',
        queryVariables: defaultQueryVariables,
        hasWorkItems: true,
        initialLoadWasFiltered: false,
        isSortKeyInitialized: true,
        state: STATUS_OPEN,
        ...props,
      },
      slots,
      stubs: {
        WorkItemBulkEditSidebar: stubComponent(WorkItemBulkEditSidebar),
      },
      mocks: {
        $toast: { show: showToast },
      },
    });
  };

  // Refetches by changing the search term, so the queries run again with new variables.
  const refetchWith = (queryVariables = {}) =>
    wrapper.setProps({ queryVariables: { ...defaultQueryVariables, ...queryVariables } });

  describe('while the initial load is in flight', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders a loading icon instead of the table', () => {
      expect(findLoadingIcon().exists()).toBe(true);
      expect(findTable().exists()).toBe(false);
    });
  });

  describe('columns', () => {
    describe('when the namespace has no licensed features', () => {
      beforeEach(async () => {
        createComponent();
        await waitForPromises();
      });

      it('renders only the columns that need no license', () => {
        expect(findColumnHeaderLabels()).toEqual([
          'Title',
          'Reference',
          'Assignees',
          'Labels',
          'Milestone',
          'Start date',
          'Due date',
          'Created date',
        ]);
      });
    });

    describe('when the namespace has every licensed feature', () => {
      beforeEach(async () => {
        createComponent({
          provide: {
            hasIssuableHealthStatusFeature: true,
            hasIssueWeightsFeature: true,
            hasIterationsFeature: true,
            hasStatusFeature: true,
          },
        });
        await waitForPromises();
      });

      it('renders the licensed columns as well', () => {
        expect(findColumnHeaderLabels()).toEqual([
          'Title',
          'Reference',
          'Status',
          'Assignees',
          'Labels',
          'Weight',
          'Milestone',
          'Iteration',
          'Start date',
          'Due date',
          'Health status',
          'Created date',
        ]);
      });
    });

    describe('when fields are hidden in the display settings', () => {
      beforeEach(async () => {
        createComponent({
          props: {
            displaySettings: {
              namespacePreferences: {
                hiddenMetadataKeys: [METADATA_KEYS.LABELS, METADATA_KEYS.DATES],
              },
            },
          },
        });
        await waitForPromises();
      });

      it('does not render a column for them', () => {
        expect(findColumnHeaderLabels()).not.toContain('Labels');
        expect(findColumnHeaderLabels()).not.toContain('Start date');
        expect(findColumnHeaderLabels()).not.toContain('Due date');
      });
    });
  });

  describe('when the work items have loaded', () => {
    beforeEach(async () => {
      createComponent();
      await waitForPromises();
    });

    it('fetches the work items with the given query variables', () => {
      expect(slimQueryHandler).toHaveBeenCalledWith(expect.objectContaining(defaultQueryVariables));
      expect(fullQueryHandler).toHaveBeenCalledWith(expect.objectContaining(defaultQueryVariables));
    });

    it('renders a row per work item', () => {
      expect(findRows()).toHaveLength(workItems.length);
      expect(findRows().at(0).props()).toMatchObject({
        item: expect.objectContaining({ id: workItems[0].id }),
        rootPageFullPath: 'group',
      });
    });

    it('passes the columns to each row so the cells line up with the headers', () => {
      expect(findRows().at(0).props('columns')).toHaveLength(findColumnHeaders().length);
    });

    it('emits the rendered work items', () => {
      expect(wrapper.emitted('work-items-changed').at(-1)).toEqual([
        { count: workItems.length, ids: workItems.map(({ id }) => id) },
      ]);
    });

    it('emits the namespace data', () => {
      expect(wrapper.emitted('namespace-data-loaded').at(-1)[0]).toMatchObject({
        namespaceName: 'Test',
      });
    });
  });

  describe('when the query is skipped', () => {
    beforeEach(async () => {
      createComponent({ props: { skipQuery: true } });
      await waitForPromises();
    });

    it('does not fetch the work items', () => {
      expect(slimQueryHandler).not.toHaveBeenCalled();
      expect(fullQueryHandler).not.toHaveBeenCalled();
    });
  });

  describe('when the REST API feature flag is enabled', () => {
    beforeEach(async () => {
      createComponent({ glFeatures: { workItemRestApiFrontendUsers: true } });
      await waitForPromises();
    });

    it('fetches the work items from the REST API', () => {
      expect(restQueryHandler).toHaveBeenCalled();
      expect(slimQueryHandler).not.toHaveBeenCalled();
      expect(fullQueryHandler).not.toHaveBeenCalled();
    });

    it('renders a row per work item', () => {
      expect(findRows()).toHaveLength(workItems.length);
    });
  });

  describe('when the query fails', () => {
    beforeEach(async () => {
      createComponent();
      slimQueryHandler.mockRejectedValue(new Error('oh no'));
      refetchWith({ search: 'retry' });
      await waitForPromises();
    });

    it('emits an error', () => {
      expect(wrapper.emitted('set-error').at(-1)).toEqual([
        'Something went wrong when fetching work items. Please try again.',
      ]);
    });
  });

  describe('when the initial load fails', () => {
    beforeEach(async () => {
      createComponent({ failQueries: true });
      await waitForPromises();
    });

    it('stops showing the loading icon', () => {
      expect(findLoadingIcon().exists()).toBe(false);
    });
  });

  describe('when a refetch is in flight', () => {
    const startRefetch = async ({ workItemsCount } = {}) => {
      createComponent({ props: { workItemsCount } });
      await waitForPromises();
      // Never resolves, so the queries are still in flight once the setup is done.
      slimQueryHandler.mockReturnValue(new Promise(() => {}));
      fullQueryHandler.mockReturnValue(new Promise(() => {}));
      refetchWith({ search: 'next' });
      await nextTick();
    };

    describe('when the number of results is known', () => {
      beforeEach(async () => {
        await startRefetch({ workItemsCount: 3 });
      });

      it('replaces the rows with skeletons', () => {
        expect(findRows()).toHaveLength(0);
        expect(findSkeletonLoaders().length).toBeGreaterThan(0);
      });

      it('renders a skeleton row per expected result', () => {
        expect(findSkeletonRows()).toHaveLength(3);
      });

      it('keeps the column headers on screen', () => {
        expect(findColumnHeaders().length).toBeGreaterThan(0);
      });
    });

    describe('when the number of results is not known yet', () => {
      beforeEach(async () => {
        await startRefetch();
      });

      it('renders a default number of skeleton rows', () => {
        expect(findSkeletonRows()).toHaveLength(DEFAULT_SKELETON_COUNT);
      });
    });
  });

  describe('when there are no results', () => {
    beforeEach(async () => {
      createComponent({ slots: { 'list-empty-state': '<div data-testid="list-empty" />' } });
      slimQueryHandler.mockResolvedValue(buildBoardWorkItemsResponse([]));
      fullQueryHandler.mockResolvedValue(buildBoardWorkItemsResponse([]));
      refetchWith({ search: 'nothing' });
      await waitForPromises();
    });

    it('renders the list empty state instead of the table', () => {
      expect(findTable().exists()).toBe(false);
      expect(wrapper.findByTestId('list-empty').exists()).toBe(true);
    });
  });

  describe('detail panel', () => {
    // The `show` param carries a base64-encoded work item reference.
    const showParam = (id) =>
      `${DETAIL_VIEW_QUERY_PARAM_NAME}=${btoa(JSON.stringify({ id, full_path: 'group' }))}`;

    describe('by default', () => {
      beforeEach(async () => {
        createComponent();
        await waitForPromises();
      });

      it('lets rows open in the panel', () => {
        expect(findRows().at(0).props()).toMatchObject({
          activeItem: null,
          detailPanelEnabled: true,
        });
      });

      it('opens the work item a row asks for', async () => {
        await findRows().at(0).vm.$emit('set-active-item', workItems[0]);

        expect(wrapper.emitted('set-active-item').at(-1)).toEqual([workItems[0]]);
      });

      it('drops the work item from the URL when a row closes the panel', async () => {
        await findRows().at(0).vm.$emit('set-active-item', null);

        expect(wrapper.emitted('set-active-item').at(-1)).toEqual([null]);
        expect(updateHistory).toHaveBeenCalled();
        expect(removeParams).toHaveBeenCalledWith([DETAIL_VIEW_QUERY_PARAM_NAME]);
      });
    });

    describe('when the work items open on their own page instead', () => {
      beforeEach(async () => {
        createComponent({
          props: { displaySettings: { commonPreferences: { shouldOpenItemsInSidePanel: false } } },
        });
        await waitForPromises();
      });

      it('tells the rows to leave their links alone', () => {
        expect(findRows().at(0).props('detailPanelEnabled')).toBe(false);
      });
    });

    describe('when the URL names a work item', () => {
      it('opens it once the rows have loaded', async () => {
        setWindowLocation(`?${showParam(2)}`);
        createComponent();
        await waitForPromises();

        expect(wrapper.emitted('set-active-item').at(-1)).toEqual([
          expect.objectContaining({ id: workItems[1].id }),
        ]);
      });

      it('drops it from the URL when no row matches', async () => {
        setWindowLocation(`?${showParam(404)}`);
        createComponent();
        await waitForPromises();

        expect(removeParams).toHaveBeenCalledWith([DETAIL_VIEW_QUERY_PARAM_NAME]);
      });
    });
  });

  describe('when an epics list has no work items at all', () => {
    beforeEach(async () => {
      createComponent({
        props: { hasWorkItems: false },
        provide: { workItemType: WORK_ITEM_TYPE_NAME_EPIC },
        slots: { 'page-empty-state': '<div data-testid="page-empty" />' },
      });
      slimQueryHandler.mockResolvedValue(buildBoardWorkItemsResponse([]));
      fullQueryHandler.mockResolvedValue(buildBoardWorkItemsResponse([]));
      refetchWith({ search: 'nothing' });
      await waitForPromises();
    });

    it('renders the page empty state instead of the table', () => {
      expect(findTable().exists()).toBe(false);
      expect(wrapper.findByTestId('page-empty').exists()).toBe(true);
    });
  });

  describe('bulk editing', () => {
    const firstWorkItem = workItems[0];

    describe('when bulk editing is off', () => {
      beforeEach(async () => {
        createComponent();
        await waitForPromises();
      });

      it('keeps the sidebar collapsed and renders no form', () => {
        expect(findBulkEditSidebar().props('expanded')).toBe(false);
        expect(findBulkEditForm().exists()).toBe(false);
      });

      it('renders no checkbox column', () => {
        expect(findColumnHeaders().at(0).text()).toBe('Title');
        expect(findRows().at(0).props('showCheckbox')).toBe(false);
      });
    });

    describe('when bulk editing is on', () => {
      beforeEach(async () => {
        createComponent({ props: { showBulkEditSidebar: true } });
        await waitForPromises();
      });

      it('expands the sidebar and renders the form for the namespace', () => {
        expect(findBulkEditSidebar().props('expanded')).toBe(true);
        expect(findBulkEditForm().props()).toMatchObject({
          checkedItems: [],
          fullPath: 'group',
          isGroup: false,
        });
      });

      it('adds a checkbox column ahead of the others', () => {
        expect(findColumnHeaders().at(0).text()).toBe('Select work item');
        expect(findColumnHeaders().at(1).text()).toBe('Title');
        expect(findRows().at(0).props('showCheckbox')).toBe(true);
      });

      it('asks for a work item to be checked when its row is checked', () => {
        findRows().at(0).vm.$emit('checked-input', true);

        expect(wrapper.emitted('set-checked-issuable-ids')).toEqual([[[firstWorkItem.id]]]);
      });

      it('leaves the checked ids alone when a checked row reports checked again', async () => {
        await wrapper.setProps({ checkedIssuableIds: [firstWorkItem.id] });
        findRows().at(0).vm.$emit('checked-input', true);

        expect(wrapper.emitted('set-checked-issuable-ids')).toBeUndefined();
      });

      it('submits through the shared form so the button sits outside it', () => {
        expect(findUpdateSelectedButton().attributes()).toMatchObject({
          form: 'work-item-list-bulk-edit',
          type: 'submit',
        });
      });

      it('asks to close the sidebar when cancelled', () => {
        findCancelButton().vm.$emit('click');

        expect(wrapper.emitted('toggle-bulk-edit-sidebar')).toEqual([[false]]);
      });
    });

    describe('with rows checked', () => {
      beforeEach(async () => {
        createComponent({
          props: { showBulkEditSidebar: true, checkedIssuableIds: [firstWorkItem.id] },
        });
        await waitForPromises();
      });

      it('marks only the checked rows', () => {
        expect(findRows().at(0).props('checked')).toBe(true);
        expect(findRows().at(1).props('checked')).toBe(false);
      });

      it('hands the checked work items to the form, not just their ids', () => {
        expect(findBulkEditForm().props('checkedItems')).toEqual([
          expect.objectContaining({ id: firstWorkItem.id }),
        ]);
      });

      it('asks for a work item to be unchecked when its row is unchecked', () => {
        findRows().at(0).vm.$emit('checked-input', false);

        expect(wrapper.emitted('set-checked-issuable-ids')).toEqual([[[]]]);
      });

      it('enables the submit button', () => {
        expect(findUpdateSelectedButton().props('disabled')).toBe(false);
      });

      describe('while an update is in flight', () => {
        beforeEach(() => {
          findBulkEditForm().vm.$emit('start');
        });

        it('shows the submit button as loading and blocks a second submit', () => {
          expect(findUpdateSelectedButton().props()).toMatchObject({
            loading: true,
            disabled: true,
          });
        });

        it('stops loading when the form finishes', async () => {
          findBulkEditForm().vm.$emit('finish');
          await nextTick();

          expect(findUpdateSelectedButton().props('loading')).toBe(false);
        });
      });

      describe('when the update succeeds', () => {
        it('closes the sidebar', () => {
          findBulkEditForm().vm.$emit('success', {});

          expect(wrapper.emitted('toggle-bulk-edit-sidebar')).toEqual([[false]]);
        });

        it('shows the toast the form asked for', () => {
          findBulkEditForm().vm.$emit('success', { toastMessage: '2 items updated' });

          expect(showToast).toHaveBeenCalledWith('2 items updated');
        });

        it('refetches the counts when the form asks for it', () => {
          findBulkEditForm().vm.$emit('success', { refetchCounts: true });

          expect(wrapper.emitted('refetch-data')).toEqual([['counts']]);
        });
      });
    });
  });
});
