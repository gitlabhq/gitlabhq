import { useLocalStorageSpy } from 'helpers/local_storage_helper';
import { MAX_FREQUENCY, SIDEBAR_PARAMS } from '~/search/store/constants';
import {
  loadDataFromLS,
  setFrequentItemToLS,
  mergeById,
  isSidebarDirty,
  formatSearchResultCount,
  getAggregationsUrl,
  prepareSearchAggregations,
  addCountOverLimit,
} from '~/search/store/utils';
import { useMockLocationHelper } from 'helpers/mock_window_location_helper';
import {
  MOCK_LS_KEY,
  MOCK_GROUPS,
  MOCK_INFLATED_DATA,
  FRESH_STORED_DATA,
  STALE_STORED_DATA,
  MOCK_AGGREGATIONS,
  SMALL_MOCK_AGGREGATIONS,
  TEST_RAW_BUCKETS,
} from '../mock_data';

const PREV_TIME = new Date().getTime() - 1;
const CURRENT_TIME = new Date().getTime();

useLocalStorageSpy();
jest.mock('~/lib/utils/accessor', () => ({
  canUseLocalStorage: jest.fn().mockReturnValue(true),
}));

describe('Global Search Store Utils', () => {
  afterEach(() => {
    localStorage.clear();
  });

  describe('loadDataFromLS', () => {
    let res;

    describe('with valid data', () => {
      beforeEach(() => {
        localStorage.setItem(MOCK_LS_KEY, JSON.stringify(MOCK_GROUPS));
        res = loadDataFromLS(MOCK_LS_KEY);
      });

      it('returns parsed array', () => {
        expect(res).toStrictEqual(MOCK_GROUPS);
      });
    });

    describe('with invalid data', () => {
      beforeEach(() => {
        localStorage.setItem(MOCK_LS_KEY, '[}');
        res = loadDataFromLS(MOCK_LS_KEY);
      });

      it('wipes local storage and returns an empty array', () => {
        expect(localStorage.removeItem).toHaveBeenCalledWith(MOCK_LS_KEY);
        expect(res).toStrictEqual(null);
      });
    });
  });

  describe('setFrequentItemToLS', () => {
    const frequentItems = {};
    let res;

    describe('with existing data', () => {
      describe(`when frequency is less than ${MAX_FREQUENCY}`, () => {
        beforeEach(() => {
          frequentItems[MOCK_LS_KEY] = [{ ...MOCK_GROUPS[0], frequency: 1, lastUsed: PREV_TIME }];
          res = setFrequentItemToLS(MOCK_LS_KEY, frequentItems, MOCK_GROUPS[0]);
        });

        it('adds 1 to the frequency, tracks lastUsed, calls localStorage.setItem and returns the array', () => {
          const updatedFrequentItems = [
            { ...MOCK_GROUPS[0], frequency: 2, lastUsed: CURRENT_TIME },
          ];

          expect(localStorage.setItem).toHaveBeenCalledWith(
            MOCK_LS_KEY,
            JSON.stringify(updatedFrequentItems),
          );
          expect(res).toEqual(updatedFrequentItems);
        });
      });

      describe(`when frequency is equal to ${MAX_FREQUENCY}`, () => {
        beforeEach(() => {
          frequentItems[MOCK_LS_KEY] = [
            { ...MOCK_GROUPS[0], frequency: MAX_FREQUENCY, lastUsed: PREV_TIME },
          ];
          res = setFrequentItemToLS(MOCK_LS_KEY, frequentItems, MOCK_GROUPS[0]);
        });

        it(`does not further increase frequency past ${MAX_FREQUENCY}, tracks lastUsed, calls localStorage.setItem, and returns the array`, () => {
          const updatedFrequentItems = [
            { ...MOCK_GROUPS[0], frequency: MAX_FREQUENCY, lastUsed: CURRENT_TIME },
          ];

          expect(localStorage.setItem).toHaveBeenCalledWith(
            MOCK_LS_KEY,
            JSON.stringify(updatedFrequentItems),
          );
          expect(res).toEqual(updatedFrequentItems);
        });
      });
    });

    describe('with no existing data', () => {
      beforeEach(() => {
        frequentItems[MOCK_LS_KEY] = [];
        res = setFrequentItemToLS(MOCK_LS_KEY, frequentItems, MOCK_GROUPS[0]);
      });

      it('adds a new entry with frequency 1, tracks lastUsed, calls localStorage.setItem, and returns the array', () => {
        const updatedFrequentItems = [{ ...MOCK_GROUPS[0], frequency: 1, lastUsed: CURRENT_TIME }];

        expect(localStorage.setItem).toHaveBeenCalledWith(
          MOCK_LS_KEY,
          JSON.stringify(updatedFrequentItems),
        );
        expect(res).toEqual(updatedFrequentItems);
      });
    });

    describe('with multiple entries', () => {
      beforeEach(() => {
        frequentItems[MOCK_LS_KEY] = [
          { id: 1, frequency: 2, lastUsed: PREV_TIME },
          { id: 2, frequency: 1, lastUsed: PREV_TIME },
          { id: 3, frequency: 1, lastUsed: PREV_TIME },
        ];
        res = setFrequentItemToLS(MOCK_LS_KEY, frequentItems, { id: 3 });
      });

      it('sorts the array by most frequent and lastUsed and returns the array', () => {
        const updatedFrequentItems = [
          { id: 3, frequency: 2, lastUsed: CURRENT_TIME },
          { id: 1, frequency: 2, lastUsed: PREV_TIME },
          { id: 2, frequency: 1, lastUsed: PREV_TIME },
        ];

        expect(localStorage.setItem).toHaveBeenCalledWith(
          MOCK_LS_KEY,
          JSON.stringify(updatedFrequentItems),
        );
        expect(res).toEqual(updatedFrequentItems);
      });
    });

    describe('with max entries', () => {
      beforeEach(() => {
        frequentItems[MOCK_LS_KEY] = [
          { id: 1, frequency: 5, lastUsed: PREV_TIME },
          { id: 2, frequency: 4, lastUsed: PREV_TIME },
          { id: 3, frequency: 3, lastUsed: PREV_TIME },
          { id: 4, frequency: 2, lastUsed: PREV_TIME },
          { id: 5, frequency: 1, lastUsed: PREV_TIME },
        ];
        res = setFrequentItemToLS(MOCK_LS_KEY, frequentItems, { id: 6 });
      });

      it('removes the last item in the array and returns the array', () => {
        const updatedFrequentItems = [
          { id: 1, frequency: 5, lastUsed: PREV_TIME },
          { id: 2, frequency: 4, lastUsed: PREV_TIME },
          { id: 3, frequency: 3, lastUsed: PREV_TIME },
          { id: 4, frequency: 2, lastUsed: PREV_TIME },
          { id: 6, frequency: 1, lastUsed: CURRENT_TIME },
        ];

        expect(localStorage.setItem).toHaveBeenCalledWith(
          MOCK_LS_KEY,
          JSON.stringify(updatedFrequentItems),
        );
        expect(res).toEqual(updatedFrequentItems);
      });
    });

    describe('with null data loaded in', () => {
      beforeEach(() => {
        frequentItems[MOCK_LS_KEY] = null;
        res = setFrequentItemToLS(MOCK_LS_KEY, frequentItems, MOCK_GROUPS[0]);
      });

      it('wipes local storage and returns empty array', () => {
        expect(localStorage.removeItem).toHaveBeenCalledWith(MOCK_LS_KEY);
        expect(res).toEqual([]);
      });
    });

    describe('with additional data', () => {
      beforeEach(() => {
        const MOCK_ADDITIONAL_DATA_GROUP = { ...MOCK_GROUPS[0], extraData: 'test' };
        frequentItems[MOCK_LS_KEY] = [];
        res = setFrequentItemToLS(MOCK_LS_KEY, frequentItems, MOCK_ADDITIONAL_DATA_GROUP);
      });

      it('parses out extra data for LS and returns the array', () => {
        const updatedFrequentItems = [{ ...MOCK_GROUPS[0], frequency: 1, lastUsed: CURRENT_TIME }];

        expect(localStorage.setItem).toHaveBeenCalledWith(
          MOCK_LS_KEY,
          JSON.stringify(updatedFrequentItems),
        );
        expect(res).toEqual(updatedFrequentItems);
      });
    });
  });

  describe.each`
    description    | inflatedData          | storedData           | response
    ${'identical'} | ${MOCK_INFLATED_DATA} | ${FRESH_STORED_DATA} | ${FRESH_STORED_DATA}
    ${'stale'}     | ${MOCK_INFLATED_DATA} | ${STALE_STORED_DATA} | ${FRESH_STORED_DATA}
    ${'empty'}     | ${MOCK_INFLATED_DATA} | ${[]}                | ${MOCK_INFLATED_DATA}
    ${'null'}      | ${MOCK_INFLATED_DATA} | ${null}              | ${MOCK_INFLATED_DATA}
  `('mergeById', ({ description, inflatedData, storedData, response }) => {
    describe(`with ${description} storedData`, () => {
      let res;

      beforeEach(() => {
        res = mergeById(inflatedData, storedData);
      });

      it('prioritizes inflatedData and preserves frequency count', () => {
        expect(response).toStrictEqual(res);
      });
    });
  });

  describe.each`
    description                             | currentQuery                                                                                           | urlQuery                                                                                               | isDirty
    ${'identical'}                          | ${{ [SIDEBAR_PARAMS[0]]: 'default', [SIDEBAR_PARAMS[1]]: 'default', [SIDEBAR_PARAMS[2]]: ['a', 'b'] }} | ${{ [SIDEBAR_PARAMS[0]]: 'default', [SIDEBAR_PARAMS[1]]: 'default', [SIDEBAR_PARAMS[2]]: ['a', 'b'] }} | ${false}
    ${'different'}                          | ${{ [SIDEBAR_PARAMS[0]]: 'default', [SIDEBAR_PARAMS[1]]: 'new', [SIDEBAR_PARAMS[2]]: ['a', 'b'] }}     | ${{ [SIDEBAR_PARAMS[0]]: 'default', [SIDEBAR_PARAMS[1]]: 'default', [SIDEBAR_PARAMS[2]]: ['a', 'c'] }} | ${true}
    ${'null/undefined'}                     | ${{ [SIDEBAR_PARAMS[0]]: null, [SIDEBAR_PARAMS[1]]: null, [SIDEBAR_PARAMS[2]]: null }}                 | ${{ [SIDEBAR_PARAMS[0]]: undefined, [SIDEBAR_PARAMS[1]]: undefined, [SIDEBAR_PARAMS[2]]: undefined }}  | ${false}
    ${'updated/undefined'}                  | ${{ [SIDEBAR_PARAMS[0]]: 'new', [SIDEBAR_PARAMS[1]]: 'new', [SIDEBAR_PARAMS[2]]: ['a', 'b'] }}         | ${{ [SIDEBAR_PARAMS[0]]: undefined, [SIDEBAR_PARAMS[1]]: undefined, [SIDEBAR_PARAMS[2]]: [] }}         | ${true}
    ${'language only no url params'}        | ${{ [SIDEBAR_PARAMS[2]]: ['a', 'b'] }}                                                                 | ${{ [SIDEBAR_PARAMS[2]]: undefined }}                                                                  | ${true}
    ${'language only url params symetric'}  | ${{ [SIDEBAR_PARAMS[2]]: ['a', 'b'] }}                                                                 | ${{ [SIDEBAR_PARAMS[2]]: ['a', 'b'] }}                                                                 | ${false}
    ${'language only url params asymetric'} | ${{ [SIDEBAR_PARAMS[2]]: ['a'] }}                                                                      | ${{ [SIDEBAR_PARAMS[2]]: ['a', 'b'] }}                                                                 | ${true}
  `('isSidebarDirty', ({ description, currentQuery, urlQuery, isDirty }) => {
    describe(`with ${description} sidebar query data`, () => {
      let res;

      beforeEach(() => {
        res = isSidebarDirty(currentQuery, urlQuery);
      });

      it(`returns ${isDirty}`, () => {
        expect(res).toStrictEqual(isDirty);
      });
    });
  });
  describe('formatSearchResultCount', () => {
    it('returns zero as string if no count is provided', () => {
      expect(formatSearchResultCount()).toStrictEqual('0');
    });
    it('returns 10K string for 10000 integer', () => {
      expect(formatSearchResultCount(10000)).toStrictEqual('10K');
    });
    it('returns 23K string for "23,000+" string', () => {
      expect(formatSearchResultCount('23,000+')).toStrictEqual('23K');
    });
  });

  describe('getAggregationsUrl', () => {
    useMockLocationHelper();
    it('returns zero as string if no count is provided', () => {
      const testURL = window.location.href;
      expect(getAggregationsUrl()).toStrictEqual(`${testURL}search/aggregations`);
    });
  });

  const TEST_LANGUAGE_QUERY = ['Markdown', 'JSON'];
  const TEST_EXPECTED_ORDERED_BUCKETS = [
    TEST_RAW_BUCKETS.find((x) => x.key === 'Markdown'),
    TEST_RAW_BUCKETS.find((x) => x.key === 'JSON'),
    ...TEST_RAW_BUCKETS.filter((x) => !TEST_LANGUAGE_QUERY.includes(x.key)),
  ];

  describe('prepareSearchAggregations', () => {
    it.each`
      description        | query                                | data                       | result
      ${'has no query'}  | ${undefined}                         | ${MOCK_AGGREGATIONS}       | ${MOCK_AGGREGATIONS}
      ${'has query'}     | ${{ language: TEST_LANGUAGE_QUERY }} | ${SMALL_MOCK_AGGREGATIONS} | ${[{ ...SMALL_MOCK_AGGREGATIONS[0], buckets: TEST_EXPECTED_ORDERED_BUCKETS }]}
      ${'has bad query'} | ${{ language: ['sdf', 'wrt'] }}      | ${SMALL_MOCK_AGGREGATIONS} | ${SMALL_MOCK_AGGREGATIONS}
    `('$description', ({ query, data, result }) => {
      expect(prepareSearchAggregations({ query }, data)).toStrictEqual(result);
    });
  });

  describe('addCountOverLimit', () => {
    it("should return '+' if count includes '+'", () => {
      expect(addCountOverLimit('10+')).toEqual('+');
    });

    it("should return empty string if count does not include '+'", () => {
      expect(addCountOverLimit('10')).toEqual('');
    });

    it('should return empty string if count is not provided', () => {
      expect(addCountOverLimit()).toEqual('');
    });
  });
});
