import {
  KEY,
  LocalStorageCache,
} from '~/import_entities/import_groups/graphql/services/local_storage_cache';

describe('Local storage cache', () => {
  let cache;
  let storage;

  beforeEach(() => {
    storage = {
      getItem: jest.fn(),
      setItem: jest.fn(),
    };

    cache = new LocalStorageCache({ storage });
  });

  describe('storage management', () => {
    const IMPORT_URL = 'http://fake.url';

    it('loads state from storage on creation', () => {
      expect(storage.getItem).toHaveBeenCalledWith(KEY);
    });

    it('saves to storage when set is called', () => {
      const STORAGE_CONTENT = { fake: 'content ' };
      cache.set(IMPORT_URL, STORAGE_CONTENT);
      expect(storage.setItem).toHaveBeenCalledWith(
        KEY,
        JSON.stringify({ [IMPORT_URL]: STORAGE_CONTENT }),
      );
    });

    it('updates status by job id', () => {
      const CHANGED_STATUS = 'changed';
      const JOB_ID = 2;

      cache.set(IMPORT_URL, {
        progress: {
          id: JOB_ID,
          status: 'original',
          hasFailures: false,
        },
      });

      cache.updateStatusByJobId(JOB_ID, CHANGED_STATUS, true);

      expect(storage.setItem).toHaveBeenCalledWith(
        KEY,
        JSON.stringify({
          [IMPORT_URL]: {
            progress: {
              id: JOB_ID,
              status: CHANGED_STATUS,
              hasFailures: true,
            },
          },
        }),
      );
    });
  });
});
