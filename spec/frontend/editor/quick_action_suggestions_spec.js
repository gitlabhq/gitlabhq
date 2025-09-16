import AccessorUtilities from '~/lib/utils/accessor';
import * as LocalStorage from '~/lib/utils/local_storage';
import {
  FREQUENT_COMMANDS_STORAGE_KEY,
  sortCommandsAlphaSafe,
  recordFrequentCommandUsage,
  prioritizeCommandsWithFrequent,
} from '~/editor/quick_action_suggestions';

describe('quick_action_suggestions', () => {
  const originalPerformance = global.performance;

  beforeEach(() => {
    jest.spyOn(AccessorUtilities, 'canUseLocalStorage').mockReturnValue(true);
    jest.spyOn(LocalStorage, 'getStorageValue').mockReturnValue({ exists: false });
    jest.spyOn(LocalStorage, 'saveStorageValue').mockImplementation(() => {});

    // Provide a deterministic performance.now for guard tests
    global.performance = {
      now: () => 100,
    };
  });

  afterEach(() => {
    jest.restoreAllMocks();
    global.performance = originalPerformance;
  });

  describe('sortCommandsAlphaSafe', () => {
    it('sorts by name case-insensitively and places nameless items last', () => {
      const items = [{ name: 'zebra' }, { name: 'Alpha' }, {}, { other: true }, { name: 'beta' }];
      const result = sortCommandsAlphaSafe(items);
      expect(result.map((i) => i.name)).toEqual(['Alpha', 'beta', 'zebra', undefined, undefined]);
    });
  });

  describe('recordFrequentCommandUsage', () => {
    it('normalizes name and persists increment to localStorage', () => {
      recordFrequentCommandUsage('alpha');
      expect(LocalStorage.saveStorageValue).toHaveBeenCalledWith(FREQUENT_COMMANDS_STORAGE_KEY, {
        '/alpha': 1,
      });

      jest.clearAllMocks();
      jest.spyOn(LocalStorage, 'getStorageValue').mockReturnValue({ exists: true, value: {} });
      recordFrequentCommandUsage('/beta');
      expect(LocalStorage.saveStorageValue).toHaveBeenCalledWith(FREQUENT_COMMANDS_STORAGE_KEY, {
        '/beta': 1,
      });
    });

    it('guards against double increment in the same frame', () => {
      recordFrequentCommandUsage('alpha');
      recordFrequentCommandUsage('alpha');
      // Only one write due to frame guard
      expect(LocalStorage.saveStorageValue).toHaveBeenCalledTimes(1);
    });

    it('no-ops when localStorage not available or invalid command', () => {
      jest.restoreAllMocks();
      jest.spyOn(AccessorUtilities, 'canUseLocalStorage').mockReturnValue(false);
      jest.spyOn(LocalStorage, 'saveStorageValue').mockImplementation(() => {});
      recordFrequentCommandUsage('alpha');
      expect(LocalStorage.saveStorageValue).not.toHaveBeenCalled();

      jest.restoreAllMocks();
      jest.spyOn(AccessorUtilities, 'canUseLocalStorage').mockReturnValue(true);
      jest.spyOn(LocalStorage, 'saveStorageValue').mockImplementation(() => {});
      recordFrequentCommandUsage('');
      recordFrequentCommandUsage(123);
      expect(LocalStorage.saveStorageValue).not.toHaveBeenCalled();
    });
  });

  describe('prioritizeCommandsWithFrequent', () => {
    it('brings frequent items to the front in frequency order and ignores unknown', () => {
      const items = [{ name: 'alpha' }, { name: 'beta' }, { name: 'zebra' }];

      jest
        .spyOn(LocalStorage, 'getStorageValue')
        .mockReturnValue({ exists: true, value: { '/beta': 5, '/alpha': 3, '/ghost': 9 } });

      const result = prioritizeCommandsWithFrequent(items);
      expect(result.map((i) => i.name)).toEqual(['beta', 'alpha', 'zebra']);
    });
  });
});
