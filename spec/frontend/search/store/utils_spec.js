import { useLocalStorageSpy } from 'helpers/local_storage_helper';
import { MAX_FREQUENCY } from '~/search/store/constants';
import { loadDataFromLS, setFrequentItemToLS } from '~/search/store/utils';
import { MOCK_LS_KEY, MOCK_GROUPS } from '../mock_data';

useLocalStorageSpy();
jest.mock('~/lib/utils/accessor', () => ({
  isLocalStorageAccessSafe: jest.fn().mockReturnValue(true),
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
        expect(res).toStrictEqual([]);
      });
    });
  });

  describe('setFrequentItemToLS', () => {
    const frequentItems = {};

    describe('with existing data', () => {
      describe(`when frequency is less than ${MAX_FREQUENCY}`, () => {
        beforeEach(() => {
          frequentItems[MOCK_LS_KEY] = [{ id: MOCK_GROUPS[0].id, frequency: 1 }];
          setFrequentItemToLS(MOCK_LS_KEY, frequentItems, MOCK_GROUPS[0]);
        });

        it('adds 1 to the frequency and calls localStorage.setItem', () => {
          expect(localStorage.setItem).toHaveBeenCalledWith(
            MOCK_LS_KEY,
            JSON.stringify([{ id: MOCK_GROUPS[0].id, frequency: 2 }]),
          );
        });
      });

      describe(`when frequency is equal to ${MAX_FREQUENCY}`, () => {
        beforeEach(() => {
          frequentItems[MOCK_LS_KEY] = [{ id: MOCK_GROUPS[0].id, frequency: MAX_FREQUENCY }];
          setFrequentItemToLS(MOCK_LS_KEY, frequentItems, MOCK_GROUPS[0]);
        });

        it(`does not further increase frequency past ${MAX_FREQUENCY} and calls localStorage.setItem`, () => {
          expect(localStorage.setItem).toHaveBeenCalledWith(
            MOCK_LS_KEY,
            JSON.stringify([{ id: MOCK_GROUPS[0].id, frequency: MAX_FREQUENCY }]),
          );
        });
      });
    });

    describe('with no existing data', () => {
      beforeEach(() => {
        frequentItems[MOCK_LS_KEY] = [];
        setFrequentItemToLS(MOCK_LS_KEY, frequentItems, MOCK_GROUPS[0]);
      });

      it('adds a new entry with frequency 1 and calls localStorage.setItem', () => {
        expect(localStorage.setItem).toHaveBeenCalledWith(
          MOCK_LS_KEY,
          JSON.stringify([{ id: MOCK_GROUPS[0].id, frequency: 1 }]),
        );
      });
    });

    describe('with multiple entries', () => {
      beforeEach(() => {
        frequentItems[MOCK_LS_KEY] = [
          { id: MOCK_GROUPS[0].id, frequency: 1 },
          { id: MOCK_GROUPS[1].id, frequency: 1 },
        ];
        setFrequentItemToLS(MOCK_LS_KEY, frequentItems, MOCK_GROUPS[1]);
      });

      it('sorts the array by most frequent', () => {
        expect(localStorage.setItem).toHaveBeenCalledWith(
          MOCK_LS_KEY,
          JSON.stringify([
            { id: MOCK_GROUPS[1].id, frequency: 2 },
            { id: MOCK_GROUPS[0].id, frequency: 1 },
          ]),
        );
      });
    });

    describe('with max entries', () => {
      beforeEach(() => {
        frequentItems[MOCK_LS_KEY] = [
          { id: 1, frequency: 5 },
          { id: 2, frequency: 4 },
          { id: 3, frequency: 3 },
          { id: 4, frequency: 2 },
          { id: 5, frequency: 1 },
        ];
        setFrequentItemToLS(MOCK_LS_KEY, frequentItems, { id: 6 });
      });

      it('removes the least frequent', () => {
        expect(localStorage.setItem).toHaveBeenCalledWith(
          MOCK_LS_KEY,
          JSON.stringify([
            { id: 1, frequency: 5 },
            { id: 2, frequency: 4 },
            { id: 3, frequency: 3 },
            { id: 4, frequency: 2 },
            { id: 6, frequency: 1 },
          ]),
        );
      });
    });

    describe('with null data loaded in', () => {
      beforeEach(() => {
        frequentItems[MOCK_LS_KEY] = null;
        setFrequentItemToLS(MOCK_LS_KEY, frequentItems, MOCK_GROUPS[0]);
      });

      it('wipes local storage', () => {
        expect(localStorage.removeItem).toHaveBeenCalledWith(MOCK_LS_KEY);
      });
    });
  });
});
