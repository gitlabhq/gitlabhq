import { identity } from 'lodash';
import { nextTick } from 'vue';
import Resolver from '~/glql/components/common/resolver.vue';
import { parse } from '~/glql/core/parser';
import { execute } from '~/glql/core/executor';
import { transform } from '~/glql/core/transformer';
import DataPresenter from '~/glql/components/presenters/data.vue';
import Pagination from '~/glql/components/common/pagination.vue';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { stubCrypto } from 'helpers/crypto';
import { useMockInternalEventsTracking } from 'helpers/tracking_internal_events_helper';
import { MOCK_ISSUES, MOCK_ISSUES_PAGE_2, MOCK_FIELDS } from '../../mock_data';

jest.mock('~/glql/core/parser');
jest.mock('~/glql/core/transformer');
jest.mock('~/glql/core/executor', () => ({
  execute: jest.fn(),
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
  aggregate: [],
  groupBy: [],
};

describe('Resolver', () => {
  let wrapper;
  const { bindInternalEventDocument } = useMockInternalEventsTracking();

  const createWrapper = (propsData = {}) => {
    wrapper = mountExtended(Resolver, {
      propsData: {
        glqlQuery: 'assignee = "foo"',
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

  beforeEach(() => {
    stubCrypto();
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

    it('does not render the presenter', () => {
      expect(findPresenter().exists()).toBe(false);
    });
  });

  describe('query successfully loads content', () => {
    beforeEach(() => {
      mockUtils();
      createWrapper();
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

    it('tracks the `render_glql_block` event', () => {
      const { trackEventSpy } = bindInternalEventDocument(wrapper.element);

      expect(trackEventSpy).toHaveBeenCalledWith(
        'render_glql_block',
        { label: expect.any(String) },
        undefined,
      );
    });

    it('renders the data presenter', () => {
      expect(findPresenter().props()).toMatchObject({
        data: { count: MOCK_ISSUES.nodes.length, ...MOCK_ISSUES },
        fields: MOCK_FIELDS,
        displayType: 'list',
        loading: false,
        aggregate: MOCK_PARSE_OUTPUT.aggregate,
        groupBy: MOCK_PARSE_OUTPUT.groupBy,
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

          findPagination().vm.$emit('loadMore');
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

        findPagination().vm.$emit('loadMore');
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
});
