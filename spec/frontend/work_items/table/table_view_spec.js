import { GlLoadingIcon, GlSkeletonLoader } from '@gitlab/ui';
import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import getWorkItemsQuery from 'ee_else_ce/work_items/list/graphql/get_work_items_full.query.graphql';
import getWorkItemsSlimQuery from 'ee_else_ce/work_items/list/graphql/get_work_items_slim.query.graphql';
import getWorkItemsRestQuery from 'ee_else_ce/work_items/list/graphql/get_work_items_rest.query.graphql';
import { CREATED_DESC } from '~/work_items/list/constants';
import { STATUS_OPEN } from '~/issues/constants';
import { METADATA_KEYS, WORK_ITEM_TYPE_NAME_EPIC } from '~/work_items/constants';
import { DEFAULT_SKELETON_COUNT } from '~/vue_shared/issuable/list/constants';
import TableView from '~/work_items/table/table_view.vue';
import WorkItemTableRow from '~/work_items/table/components/work_item_table_row.vue';
import {
  buildBoardWorkItemsResponse,
  buildBoardRestWorkItemsResponse,
  buildWorkItemNode,
} from '../board/mock_data';

jest.mock('~/sentry/sentry_browser_wrapper');

Vue.use(VueApollo);

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
});
