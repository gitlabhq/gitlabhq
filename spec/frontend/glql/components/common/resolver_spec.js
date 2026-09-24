import { identity } from 'lodash-es';
import { nextTick } from 'vue';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import Resolver from '~/glql/components/common/resolver.vue';
import { parse } from '~/glql/core/parser';
import { execute } from '~/glql/core/executor';
import { transform } from '~/glql/core/transformer';
import DataPresenter from '~/glql/components/presenters/data.vue';
import Pagination from '~/glql/components/common/pagination.vue';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { useMockInternalEventsTracking } from 'helpers/tracking_internal_events_helper';
import {
  MOCK_AGGREGATED_FIELDS_ONE_DIM_ONE_METRIC,
  MOCK_AGGREGATED_PAGES,
  MOCK_ISSUES,
  MOCK_ISSUES_PAGE_2,
  MOCK_FIELDS,
} from '../../mock_data';

jest.mock('~/sentry/sentry_browser_wrapper');
jest.mock('~/glql/core/parser');
jest.mock('~/glql/core/transformer');
jest.mock('~/glql/core/executor', () => ({
  execute: jest.fn(),
}));
jest.mock('~/lib/utils/text_utility', () => ({
  sha256: jest.fn().mockResolvedValue('mock-sha256-hash'),
}));

const MOCK_PARSE_OUTPUT = {
  query: 'query {}',
  config: { display: 'list', title: 'Some title', description: 'Some description' },
  variables: {
    limit: { value: null, type: 'Int' },
    after: { value: null, type: 'String' },
    before: { value: null, type: 'String' },
  },
  fields: MOCK_FIELDS,
  mode: 'standard',
  source: 'WorkItems',
};

describe('Resolver', () => {
  let wrapper;
  const { bindInternalEventDocument } = useMockInternalEventsTracking();

  const createWrapper = (propsData = {}) => {
    wrapper = mountExtended(Resolver, {
      propsData: {
        glqlQuery: 'assignee = "foo"',
        trackingEventName: 'render_glql_block',
        ...propsData,
      },
    });
  };

  const mockUtils = ({
    parseError = false,
    executeError = false,
    transformError = false,
    totalCount = undefined,
  } = {}) => {
    if (parseError) {
      parse.mockRejectedValue(new Error('parse error'));
    } else {
      parse.mockResolvedValue(MOCK_PARSE_OUTPUT);
    }

    if (executeError) {
      execute.mockRejectedValue(new Error('execute error'));
    } else {
      execute.mockResolvedValue({
        count: totalCount ?? MOCK_ISSUES.nodes.length,
        ...MOCK_ISSUES,
      });
    }

    if (transformError) {
      transform.mockRejectedValue(new Error('transform error'));
    } else {
      transform.mockImplementation(identity);
    }
  };

  const expectEmittedChanges = (changes) => {
    expect(wrapper.emitted('change')).toHaveLength(changes.length);
    changes.forEach((change, index) => {
      expect(wrapper.emitted('change')[index][0]).toMatchObject(change);
    });
  };

  const findPresenter = () => wrapper.findComponent(DataPresenter);
  const findPagination = () => wrapper.findComponent(Pagination);

  describe('scope', () => {
    beforeEach(() => {
      mockUtils();
    });

    it('parses the query with no scope by default', async () => {
      createWrapper();
      await waitForPromises();

      expect(parse).toHaveBeenCalledWith('assignee = "foo"', null, { bindings: [] });
    });

    it('parses the query with the given scope', async () => {
      createWrapper({ scope: { group: 'gitlab-org' } });
      await waitForPromises();

      expect(parse).toHaveBeenCalledWith(
        'assignee = "foo"',
        { group: 'gitlab-org' },
        {
          bindings: [],
        },
      );
    });
  });

  describe('bindings', () => {
    const bindings = [
      {
        target: { kind: 'filter', field: 'group' },
        value: { kind: 'list', values: ['gitlab-org'] },
      },
    ];

    beforeEach(() => {
      mockUtils();
    });

    it('hands them to the compiler', async () => {
      createWrapper({ bindings });
      await waitForPromises();

      expect(parse).toHaveBeenCalledWith('assignee = "foo"', null, { bindings });
    });
  });

  describe('queue', () => {
    beforeEach(() => {
      mockUtils();
    });

    it('runs the query on the default queue', async () => {
      createWrapper();
      await waitForPromises();

      expect(execute).toHaveBeenCalledWith(
        'query {}',
        expect.anything(),
        expect.objectContaining({ queue: 'glql-queue-default' }),
      );
    });

    it('runs the query on the given queue', async () => {
      createWrapper({ queue: 'glql-queue-dashboard' });
      await waitForPromises();

      expect(execute).toHaveBeenCalledWith(
        'query {}',
        expect.anything(),
        expect.objectContaining({ queue: 'glql-queue-dashboard' }),
      );
    });

    it('runs the comparison query and further pages on the same queue', async () => {
      mockUtils({ totalCount: MOCK_ISSUES.nodes.length + 1 });
      createWrapper({ queue: 'glql-queue-dashboard', comparison: { query: 'assignee = "bar"' } });
      await waitForPromises();

      execute.mockResolvedValue({ count: MOCK_ISSUES.nodes.length + 1, ...MOCK_ISSUES_PAGE_2 });
      findPagination().vm.$emit('load-more');
      await waitForPromises();

      expect(execute.mock.calls).toEqual([
        ['query {}', expect.anything(), expect.objectContaining({ queue: 'glql-queue-dashboard' })],
        ['query {}', expect.anything(), expect.objectContaining({ queue: 'glql-queue-dashboard' })],
        ['query {}', expect.anything(), expect.objectContaining({ queue: 'glql-queue-dashboard' })],
      ]);
    });
  });

  describe('when the component is destroyed', () => {
    beforeEach(async () => {
      mockUtils();
      execute.mockReturnValue(new Promise(() => {}));

      createWrapper();
      await waitForPromises();
    });

    it('aborts the signal its queued requests carry', () => {
      const { signal } = execute.mock.calls[0][2];

      expect(signal.aborted).toBe(false);

      wrapper.destroy();

      expect(signal.aborted).toBe(true);
    });
  });

  describe('when no query is set', () => {
    beforeEach(() => {
      return createWrapper({ glqlQuery: '' });
    });

    it('does not try to parse the query', () => {
      expect(parse).not.toHaveBeenCalled();
    });

    it('does not emit any changes', () => {
      expect(wrapper.emitted('change')).toBeUndefined();
    });

    it('does not render the presenter', () => {
      expect(findPresenter().exists()).toBe(false);
    });
  });

  describe('when execute fails after a successful parse', () => {
    beforeEach(() => {
      mockUtils({ executeError: true });
      createWrapper();
      return waitForPromises();
    });

    // Consumers size their error states by the display type, which the query still declares.
    it('keeps the parsed config through the failure', () => {
      expect(wrapper.emitted('change').at(-1)[0]).toMatchObject({
        error: new Error('execute error'),
        config: MOCK_PARSE_OUTPUT.config,
      });
    });
  });

  describe.each(['parse', 'execute', 'transform'])('when %s throws an error', (errorUtil) => {
    beforeEach(() => {
      mockUtils({
        parseError: errorUtil === 'parse',
        executeError: errorUtil === 'execute',
        transformError: errorUtil === 'transform',
      });

      createWrapper();
      return waitForPromises();
    });

    it('emits change event with error payload', () => {
      expectEmittedChanges([{ loading: true }, { loading: false, error: expect.any(Error) }]);
    });

    it('does not send any tracking events', () => {
      const { trackEventSpy } = bindInternalEventDocument(wrapper.element);
      expect(trackEventSpy).not.toHaveBeenCalled();
    });

    it('does not render the presenter', () => {
      expect(findPresenter().exists()).toBe(false);
    });
  });

  describe('tracking events', () => {
    beforeEach(() => {
      mockUtils();
      createWrapper();
      return waitForPromises();
    });

    it('tracks the event defined by `trackingEventName`', () => {
      const { trackEventSpy } = bindInternalEventDocument(wrapper.element);

      expect(trackEventSpy).toHaveBeenCalledWith(
        'render_glql_block',
        { label: expect.any(String) },
        undefined,
      );
    });
  });

  describe('query successfully loads content', () => {
    beforeEach(() => {
      mockUtils();
      createWrapper({ trackingEventName: '' });
      return waitForPromises();
    });

    it('emits the change event with the loaded data', () => {
      expectEmittedChanges([
        { loading: true },
        {
          loading: false,
          data: { count: MOCK_ISSUES.nodes.length, ...MOCK_ISSUES },
          ...MOCK_PARSE_OUTPUT,
        },
      ]);
    });

    it('does not track the query render when `trackingEventName` has not been set', () => {
      const { trackEventSpy } = bindInternalEventDocument(wrapper.element);
      expect(trackEventSpy).not.toHaveBeenCalled();
    });

    it('renders the data presenter', () => {
      expect(findPresenter().props()).toMatchObject({
        data: { count: MOCK_ISSUES.nodes.length, ...MOCK_ISSUES },
        fields: MOCK_FIELDS,
        displayType: 'list',
        source: 'WorkItems',
        loading: false,
      });
    });

    it('drops the rows and emits the error when the data presenter fails', async () => {
      const error = new Error('presenter error');
      findPresenter().vm.$emit('error', error);
      await nextTick();

      // The presenter cannot render these rows, so nothing is worth keeping on screen.
      expectEmittedChanges([{ loading: true }, { loading: false }, { error, data: undefined }]);
      expect(findPresenter().exists()).toBe(false);
    });

    it('does not show the pagination component', () => {
      expect(findPagination().exists()).toBe(false);
    });
  });

  describe('query loads paginated content', () => {
    const totalCount = 3;

    beforeEach(() => {
      mockUtils({ totalCount });
      createWrapper();
      return waitForPromises();
    });

    it('shows the pagination component', () => {
      expect(findPagination().props()).toMatchObject({
        count: MOCK_ISSUES.nodes.length,
        loading: false,
        totalCount,
      });
    });

    describe.each(['execute', 'transform'])(
      'when more data is loaded but %s throws an error',
      (errorUtil) => {
        beforeEach(() => {
          mockUtils({
            executeError: errorUtil === 'execute',
            transformError: errorUtil === 'transform',
          });

          findPagination().vm.$emit('load-more');
          return waitForPromises();
        });

        it('emits change event with error payload', () => {
          expectEmittedChanges([
            { loading: true },
            { loading: false },
            {
              loading: true,
              data: { count: totalCount, ...MOCK_ISSUES },
            },
            {
              loading: false,
              data: { count: totalCount, ...MOCK_ISSUES },
              error: expect.any(Error),
            },
          ]);
        });

        it('renders the presenter', () => {
          expect(findPresenter().exists()).toBe(true);
        });
      },
    );

    describe('when more data is loaded', () => {
      beforeEach(() => {
        execute.mockResolvedValue({
          count: totalCount,
          ...MOCK_ISSUES_PAGE_2,
        });

        findPagination().vm.$emit('load-more');
        return waitForPromises();
      });

      it('emits change event with new data appended', () => {
        expectEmittedChanges([
          { loading: true },
          { loading: false },
          {
            loading: true,
            data: { count: totalCount, ...MOCK_ISSUES },
          },
          {
            loading: false,
            data: { count: totalCount, nodes: [...MOCK_ISSUES.nodes, ...MOCK_ISSUES_PAGE_2.nodes] },
          },
        ]);
      });
    });
  });

  describe('with a comparison query', () => {
    const GLQL_QUERY =
      'type = AiUsageEvent and timestamp >= "2026-08-06" and timestamp <= "2026-09-05"';
    const COMPARISON_QUERY =
      'type = AiUsageEvent and timestamp >= "2026-07-06" and timestamp <= "2026-08-05"';
    const SCOPE = { group: 'gitlab-org' };
    const CURRENT = { nodes: [{ usersCount: 120 }] };
    const PREVIOUS = { nodes: [{ usersCount: 100 }] };

    const PARSE_OUTPUT = {
      ...MOCK_PARSE_OUTPUT,
      config: { display: 'stat' },
      fields: [{ key: 'usersCount', name: 'usersCount', type: 'metric' }],
      mode: 'analytics',
      source: 'AiUsageEvents',
    };

    const isComparison = (query) => query === 'query previous {}';

    // Each query compiles to its own GraphQL document, which is how execute tells them apart.
    const mockParse = () =>
      parse.mockImplementation((glqlQuery) =>
        Promise.resolve(
          glqlQuery === COMPARISON_QUERY
            ? { ...PARSE_OUTPUT, query: 'query previous {}' }
            : PARSE_OUTPUT,
        ),
      );

    const setup = async () => {
      mockParse();
      execute.mockImplementation((query) =>
        Promise.resolve(isComparison(query) ? PREVIOUS : CURRENT),
      );
      transform.mockImplementation(identity);

      createWrapper({
        glqlQuery: GLQL_QUERY,
        comparison: { query: COMPARISON_QUERY },
        scope: SCOPE,
      });
      await waitForPromises();
    };

    it('compiles the comparison query against the same scope', async () => {
      await setup();

      expect(parse.mock.calls).toEqual([
        [GLQL_QUERY, SCOPE, { bindings: [] }],
        [COMPARISON_QUERY, SCOPE, { bindings: [] }],
      ]);
    });

    describe('while the main query is still running', () => {
      let resolveCurrent;

      beforeEach(async () => {
        mockParse();
        execute.mockImplementation((query) =>
          isComparison(query)
            ? Promise.resolve(PREVIOUS)
            : new Promise((resolve) => {
                resolveCurrent = resolve;
              }),
        );
        transform.mockImplementation(identity);

        createWrapper({ glqlQuery: GLQL_QUERY, comparison: { query: COMPARISON_QUERY } });
        await waitForPromises();
      });

      it('runs the comparison query without waiting for it', () => {
        expect(execute.mock.calls.map(([query]) => query)).toEqual([
          'query {}',
          'query previous {}',
        ]);
      });

      it('holds back the comparison result until the main one arrives', () => {
        expect(findPresenter().props()).toMatchObject({ loading: true, comparisonData: null });
        expectEmittedChanges([{ loading: true }]);
      });

      describe('when the main query resolves', () => {
        beforeEach(async () => {
          resolveCurrent(CURRENT);
          await waitForPromises();
        });

        it('renders both results in a single change', () => {
          expect(findPresenter().props()).toMatchObject({
            loading: false,
            data: CURRENT,
            comparisonData: PREVIOUS,
          });
          expectEmittedChanges([
            { loading: true },
            { loading: false, data: CURRENT, comparisonData: PREVIOUS },
          ]);
        });
      });
    });

    it('drops the comparison when the main result outgrows a single page', async () => {
      mockParse();
      execute.mockImplementation((query) =>
        Promise.resolve(isComparison(query) ? PREVIOUS : { ...CURRENT, count: 101 }),
      );
      transform.mockImplementation(identity);

      createWrapper({ glqlQuery: GLQL_QUERY, comparison: { query: COMPARISON_QUERY } });
      await waitForPromises();

      expect(findPresenter().props()).toMatchObject({
        data: { ...CURRENT, count: 101 },
        comparisonData: null,
      });
    });

    it('keeps the comparison when the main result fills exactly one page', async () => {
      mockParse();
      execute.mockImplementation((query) =>
        Promise.resolve(isComparison(query) ? PREVIOUS : { ...CURRENT, count: 100 }),
      );
      transform.mockImplementation(identity);

      createWrapper({ glqlQuery: GLQL_QUERY, comparison: { query: COMPARISON_QUERY } });
      await waitForPromises();

      expect(findPresenter().props('comparisonData')).toEqual(PREVIOUS);
    });

    describe('when the main query fails', () => {
      const mainError = new Error('main execute error');
      const comparisonError = new Error('comparison execute error');

      beforeEach(async () => {
        mockParse();
        execute.mockImplementation((query) =>
          Promise.reject(isComparison(query) ? comparisonError : mainError),
        );
        transform.mockImplementation(identity);

        createWrapper({ glqlQuery: GLQL_QUERY, comparison: { query: COMPARISON_QUERY } });
        await waitForPromises();
      });

      it('reports the main error without a comparison', () => {
        expect(wrapper.emitted('change').slice(-1)[0][0]).toMatchObject({
          loading: false,
          error: mainError,
          data: undefined,
          comparisonData: undefined,
        });
      });

      it('still captures the comparison failure for debugging', () => {
        expect(Sentry.captureException).toHaveBeenCalledWith(comparisonError);
      });
    });

    it('renders both results through the presenter', async () => {
      await setup();

      expect(findPresenter().props()).toMatchObject({
        data: CURRENT,
        comparisonData: PREVIOUS,
        displayType: 'stat',
      });
    });

    it('attaches the trend metric to the comparison result', async () => {
      mockParse();
      execute.mockImplementation((query) =>
        Promise.resolve(isComparison(query) ? PREVIOUS : CURRENT),
      );
      transform.mockImplementation(identity);

      createWrapper({
        glqlQuery: GLQL_QUERY,
        comparison: { query: COMPARISON_QUERY, metric: 'totalCount' },
      });
      await waitForPromises();

      expect(findPresenter().props('comparisonData')).toEqual({
        ...PREVIOUS,
        metric: 'totalCount',
      });
    });

    it('emits the change event with the main result as the data', async () => {
      await setup();

      expectEmittedChanges([
        { loading: true },
        { loading: false, data: CURRENT, comparisonData: PREVIOUS },
      ]);
    });

    describe.each([
      [
        'compile',
        'comparison parse error',
        (rejection) => {
          parse.mockImplementation((glqlQuery) =>
            glqlQuery === COMPARISON_QUERY
              ? Promise.reject(rejection)
              : Promise.resolve(PARSE_OUTPUT),
          );
          execute.mockResolvedValue(CURRENT);
        },
      ],
      [
        'run',
        'comparison execute error',
        (rejection) => {
          mockParse();
          execute.mockImplementation((query) =>
            isComparison(query) ? Promise.reject(rejection) : Promise.resolve(CURRENT),
          );
        },
      ],
    ])('when the comparison query fails to %s', (_, message, mockFailure) => {
      const error = new Error(message);

      beforeEach(async () => {
        mockFailure(error);
        transform.mockImplementation(identity);

        createWrapper({ glqlQuery: GLQL_QUERY, comparison: { query: COMPARISON_QUERY } });
        await waitForPromises();
      });

      it('renders the main result without the comparison', () => {
        expect(findPresenter().props()).toMatchObject({ data: CURRENT, comparisonData: null });
      });

      it('does not report an error', () => {
        expect(wrapper.emitted('change').slice(-1)[0][0]).toMatchObject({
          error: undefined,
          data: CURRENT,
          comparisonData: undefined,
        });
      });

      it('captures the failure for debugging', () => {
        expect(Sentry.captureException).toHaveBeenCalledWith(error);
      });
    });

    describe('when the component is destroyed while the comparison is pending', () => {
      let rejectComparison;

      beforeEach(async () => {
        mockParse();
        execute.mockImplementation((query) =>
          isComparison(query)
            ? new Promise((_resolve, reject) => {
                rejectComparison = reject;
              })
            : Promise.resolve(CURRENT),
        );
        transform.mockImplementation(identity);

        createWrapper({
          glqlQuery: GLQL_QUERY,
          comparison: { query: COMPARISON_QUERY },
          scope: SCOPE,
        });
        await waitForPromises();

        wrapper.destroy();
      });

      it('does not report the comparison the queue dropped', async () => {
        rejectComparison(execute.mock.calls[1][2].signal.reason);
        await waitForPromises();

        expect(Sentry.captureException).not.toHaveBeenCalled();
      });

      it('still reports a comparison that failed for another reason', async () => {
        const error = new Error('Internal server error');

        rejectComparison(error);
        await waitForPromises();

        expect(Sentry.captureException).toHaveBeenCalledWith(error);
      });
    });

    it('runs a single query without a comparison query', async () => {
      parse.mockResolvedValue(PARSE_OUTPUT);
      execute.mockResolvedValue(CURRENT);
      transform.mockImplementation(identity);

      createWrapper({ glqlQuery: GLQL_QUERY });
      await waitForPromises();

      expect(parse).toHaveBeenCalledTimes(1);
      expect(execute).toHaveBeenCalledTimes(1);
      expect(findPresenter().props('comparisonData')).toBeNull();
    });

    describe('when more data is loaded', () => {
      const TOTAL_COUNT = 3;

      beforeEach(async () => {
        // Fresh variables per parse, so the cursor set on the main query is visible in the call.
        parse.mockImplementation((glqlQuery) =>
          Promise.resolve({
            ...MOCK_PARSE_OUTPUT,
            query: glqlQuery === COMPARISON_QUERY ? 'query previous {}' : 'query {}',
            variables: {
              limit: { value: null, type: 'Int' },
              after: { value: null, type: 'String' },
            },
          }),
        );
        execute.mockImplementation((query, variables) => {
          if (isComparison(query)) return Promise.resolve({ count: TOTAL_COUNT, ...MOCK_ISSUES });
          if (variables.after.value == null) {
            return Promise.resolve({
              count: TOTAL_COUNT,
              pageInfo: { endCursor: 'current-cursor' },
              ...MOCK_ISSUES,
            });
          }
          return Promise.resolve({ count: TOTAL_COUNT, ...MOCK_ISSUES_PAGE_2 });
        });
        transform.mockImplementation(identity);

        createWrapper({ glqlQuery: GLQL_QUERY, comparison: { query: COMPARISON_QUERY } });
        await waitForPromises();
        execute.mockClear();

        findPagination().vm.$emit('load-more');
        await waitForPromises();
      });

      it('pages the main query alone', () => {
        expect(execute.mock.calls).toEqual([
          [
            'query {}',
            expect.objectContaining({ after: { value: 'current-cursor', type: 'String' } }),
            expect.anything(),
          ],
        ]);
      });

      it('appends the page to the main result and keeps the comparison as first loaded', () => {
        expect(findPresenter().props()).toMatchObject({
          data: { count: TOTAL_COUNT, nodes: [...MOCK_ISSUES.nodes, ...MOCK_ISSUES_PAGE_2.nodes] },
          comparisonData: { count: TOTAL_COUNT, nodes: MOCK_ISSUES.nodes },
        });
      });
    });
  });

  describe('per-display-type pagination behaviour', () => {
    // Setting totalCount higher than the loaded nodes is what makes the
    // resolver think "more data exists". hasNextPage only flips to true when
    // the display type *also* maps to load-more in PAGINATION_BY_DISPLAY_TYPE.
    const TOTAL_COUNT_WITH_MORE_DATA = MOCK_ISSUES.nodes.length + 30;

    const parseOutputFor = ({ display, limit = null }) => ({
      ...MOCK_PARSE_OUTPUT,
      config: {
        ...(display !== undefined && { display }),
        ...(limit != null && { limit }),
      },
      variables: {
        limit: { value: null, type: 'Int' },
        after: { value: null, type: 'String' },
        before: { value: null, type: 'String' },
      },
    });

    const setup = async ({ display, limit = null } = {}) => {
      mockUtils({ totalCount: TOTAL_COUNT_WITH_MORE_DATA });
      parse.mockResolvedValue(parseOutputFor({ display, limit }));
      createWrapper();
      await waitForPromises();
    };

    const lastEmittedChange = () => wrapper.emitted('change').slice(-1)[0][0];

    describe.each(['columnChart', 'lineChart'])('non-paginated display type: %s', (display) => {
      it('does not set the default limit variable', async () => {
        await setup({ display });

        expect(execute).toHaveBeenCalledWith(
          expect.anything(),
          expect.objectContaining({ limit: { value: null, type: 'Int' } }),
          expect.anything(),
        );
      });

      it('honors an explicit limit from the GLQL block', async () => {
        await setup({ display, limit: 5 });

        expect(execute).toHaveBeenCalledWith(
          expect.anything(),
          expect.objectContaining({ limit: { value: 5, type: 'Int' } }),
          expect.anything(),
        );
      });

      it('does not render pagination even when more data exists', async () => {
        await setup({ display });

        expect(findPagination().exists()).toBe(false);
      });

      it('emits hasNextPage as false', async () => {
        await setup({ display });

        expect(lastEmittedChange().hasNextPage).toBe(false);
      });
    });

    describe.each([
      ['list', 'list'],
      ['orderedList', 'orderedList'],
      ['table', 'table'],
      ['(no display)', undefined],
    ])('paginated display type: %s', (_label, display) => {
      it('applies the default page size when no limit is set', async () => {
        await setup({ display });

        expect(execute).toHaveBeenCalledWith(
          expect.anything(),
          expect.objectContaining({ limit: { value: 20, type: 'Int' } }),
          expect.anything(),
        );
      });

      it('honors an explicit limit from the GLQL block', async () => {
        await setup({ display, limit: 5 });

        expect(execute).toHaveBeenCalledWith(
          expect.anything(),
          expect.objectContaining({ limit: { value: 5, type: 'Int' } }),
          expect.anything(),
        );
      });

      it('preserves an explicit limit across load-more calls', async () => {
        await setup({ display, limit: 5 });
        execute.mockClear();
        execute.mockResolvedValue({
          count: TOTAL_COUNT_WITH_MORE_DATA,
          ...MOCK_ISSUES_PAGE_2,
        });

        findPagination().vm.$emit('load-more');
        await waitForPromises();

        expect(execute).toHaveBeenCalledWith(
          expect.anything(),
          expect.objectContaining({ limit: { value: 5, type: 'Int' } }),
          expect.anything(),
        );
      });

      it('renders pagination when more data exists', async () => {
        await setup({ display });

        expect(findPagination().exists()).toBe(true);
      });

      it('passes the default page size to the pagination component when no limit is set', async () => {
        await setup({ display });

        expect(findPagination().props('pageSize')).toBe(20);
      });

      it('passes the explicit limit to the pagination component', async () => {
        await setup({ display, limit: 5 });

        expect(findPagination().props('pageSize')).toBe(5);
      });

      it('emits hasNextPage as true when more data exists', async () => {
        await setup({ display });

        expect(lastEmittedChange().hasNextPage).toBe(true);
      });
    });
  });
  describe('auto-pagination for aggregated displays', () => {
    const CHART_PAGE_SIZE = 100;
    let cursorsRequested;

    const mockParseOutput = ({ display, limit = null }) => ({
      ...MOCK_PARSE_OUTPUT,
      config: { display, ...(limit != null && { limit }) },
      fields: MOCK_AGGREGATED_FIELDS_ONE_DIM_ONE_METRIC,
      mode: 'analytics',
      variables: {
        limit: { value: null, type: 'Int' },
        after: { value: null, type: 'String' },
        before: { value: null, type: 'String' },
      },
    });

    const setup = async ({ display = 'columnChart', limit = null, pages, respond }) => {
      parse.mockResolvedValue(mockParseOutput({ display, limit }));
      transform.mockImplementation(identity);

      // `variables` is mutated in place, so cursors are captured per request, not read back.
      cursorsRequested = [];
      execute.mockReset();
      execute.mockImplementation((_query, variables) => {
        cursorsRequested.push(variables.after.value);
        const page = cursorsRequested.length - 1;
        return respond ? respond(page) : Promise.resolve(pages[Math.min(page, pages.length - 1)]);
      });

      createWrapper();
      await waitForPromises();
    };

    const lastEmittedChange = () => wrapper.emitted('change').slice(-1)[0][0];

    describe('when every page is reachable', () => {
      beforeEach(() => setup({ pages: MOCK_AGGREGATED_PAGES }));

      it('requests a full page for each page in turn, advancing the cursor', () => {
        expect(cursorsRequested).toEqual([null, 'cursor-1', 'cursor-2']);
        expect(execute).toHaveBeenLastCalledWith(
          expect.anything(),
          expect.objectContaining({ limit: { value: CHART_PAGE_SIZE, type: 'Int' } }),
          expect.anything(),
        );
      });

      it('renders every aggregated row in order and reports no truncation', () => {
        expect(findPresenter().props('data').nodes).toEqual([
          { language: 'ruby', totalCount: 10 },
          { language: 'js', totalCount: 9 },
          { language: 'go', totalCount: 8 },
          { language: 'rust', totalCount: 7 },
          { language: 'python', totalCount: 6 },
        ]);
        expect(lastEmittedChange().resultsTruncated).toBe(false);
      });

      it('emits change once for the whole fetch rather than once per page', () => {
        expect(wrapper.emitted('change')).toHaveLength(2);
        expect(wrapper.emitted('change')[0][0]).toMatchObject({ loading: true });
        expect(wrapper.emitted('change')[1][0]).toMatchObject({ loading: false });
      });
    });

    it('stops at the row cap and reports the results as truncated', async () => {
      await setup({
        respond: (page) =>
          Promise.resolve({
            count: 5000,
            pageInfo: { endCursor: `cursor-${page + 1}`, hasNextPage: true },
            nodes: new Array(CHART_PAGE_SIZE).fill({ language: 'ruby', totalCount: 1 }),
          }),
      });

      expect(execute).toHaveBeenCalledTimes(10);
      expect(findPresenter().props('data').nodes).toHaveLength(1000);
      expect(lastEmittedChange().resultsTruncated).toBe(true);
    });

    it('stops when the backend reports no further page, whatever the count says', async () => {
      await setup({
        pages: [
          {
            count: 500,
            pageInfo: { endCursor: 'cursor-1', hasNextPage: false },
            nodes: MOCK_AGGREGATED_PAGES[0].nodes,
          },
        ],
      });

      expect(execute).toHaveBeenCalledTimes(1);
      expect(lastEmittedChange().resultsTruncated).toBe(true);
    });

    it('stops at the request cap when pages come back empty', async () => {
      await setup({
        respond: (page) =>
          Promise.resolve({
            count: 500,
            pageInfo: { endCursor: `cursor-${page + 1}`, hasNextPage: true },
            nodes: page === 0 ? MOCK_AGGREGATED_PAGES[0].nodes : [],
          }),
      });

      expect(execute).toHaveBeenCalledTimes(11);
      expect(findPresenter().props('data').nodes).toEqual(MOCK_AGGREGATED_PAGES[0].nodes);
    });

    it('stops when the response carries no cursor to advance to', async () => {
      await setup({ pages: [{ count: 5, nodes: MOCK_AGGREGATED_PAGES[0].nodes }] });

      expect(execute).toHaveBeenCalledTimes(1);
      expect(lastEmittedChange().resultsTruncated).toBe(true);
    });

    it('does not paginate when the GLQL block sets an explicit limit', async () => {
      await setup({ limit: 2, pages: MOCK_AGGREGATED_PAGES });

      expect(execute).toHaveBeenCalledTimes(1);
      expect(lastEmittedChange().resultsTruncated).toBe(false);
    });

    it('does not paginate a table display, which offers load-more instead', async () => {
      await setup({
        display: 'table',
        pages: [
          { count: 5, pageInfo: { endCursor: 'cursor-1', hasNextPage: true }, ...MOCK_ISSUES },
        ],
      });

      expect(execute).toHaveBeenCalledTimes(1);
      expect(findPagination().exists()).toBe(true);
    });

    it('stops paginating once the component is destroyed', async () => {
      let finishSecondPage;
      await setup({
        respond: (page) =>
          page === 1
            ? new Promise((resolve) => {
                finishSecondPage = resolve;
              })
            : Promise.resolve(MOCK_AGGREGATED_PAGES[Math.min(page, 2)]),
      });

      wrapper.destroy();
      finishSecondPage(MOCK_AGGREGATED_PAGES[1]);
      await waitForPromises();

      expect(execute).toHaveBeenCalledTimes(2);
    });

    describe('when a continuation page fails', () => {
      beforeEach(() =>
        setup({
          respond: (page) =>
            page === 0
              ? Promise.resolve(MOCK_AGGREGATED_PAGES[0])
              : Promise.reject(new Error('execute error')),
        }),
      );

      it('keeps the pages already loaded', () => {
        expect(findPresenter().props('data').nodes).toEqual(MOCK_AGGREGATED_PAGES[0].nodes);
      });

      it('reports the results as truncated without surfacing an error', () => {
        expect(lastEmittedChange()).toMatchObject({ resultsTruncated: true, error: undefined });
      });

      it('reports the failure to Sentry', () => {
        expect(Sentry.captureException).toHaveBeenCalledWith(new Error('execute error'));
      });
    });
  });
});
