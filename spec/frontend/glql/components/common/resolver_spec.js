import { identity } from 'lodash-es';
import { nextTick } from 'vue';
import Resolver from '~/glql/components/common/resolver.vue';
import { parse } from '~/glql/core/parser';
import { execute } from '~/glql/core/executor';
import { transform } from '~/glql/core/transformer';
import DataPresenter from '~/glql/components/presenters/data.vue';
import Pagination from '~/glql/components/common/pagination.vue';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { useMockInternalEventsTracking } from 'helpers/tracking_internal_events_helper';
import { MOCK_ISSUES, MOCK_ISSUES_PAGE_2, MOCK_FIELDS } from '../../mock_data';

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
        loading: false,
      });
    });

    it('emits change event with error payload when data presenter has an error', async () => {
      const error = new Error('presenter error');
      findPresenter().vm.$emit('error', error);
      await nextTick();

      expectEmittedChanges([{ loading: true }, { loading: false }, { error }]);
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

  describe('per-display-type pagination behaviour', () => {
    // Setting totalCount higher than the loaded nodes is what makes the
    // resolver think "more data exists". hasNextPage only flips to true when
    // the display type *also* opts into pagination via PAGINATED_DISPLAY_TYPES_WITH_DEFAULT_LIMIT.
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
        );
      });

      it('honors an explicit limit from the GLQL block', async () => {
        await setup({ display, limit: 5 });

        expect(execute).toHaveBeenCalledWith(
          expect.anything(),
          expect.objectContaining({ limit: { value: 5, type: 'Int' } }),
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
        );
      });

      it('honors an explicit limit from the GLQL block', async () => {
        await setup({ display, limit: 5 });

        expect(execute).toHaveBeenCalledWith(
          expect.anything(),
          expect.objectContaining({ limit: { value: 5, type: 'Int' } }),
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
});
