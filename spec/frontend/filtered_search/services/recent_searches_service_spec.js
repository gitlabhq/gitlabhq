import { useLocalStorageSpy } from 'helpers/local_storage_helper';
import RecentSearchesService from '~/filtered_search/services/recent_searches_service';
import RecentSearchesServiceError from '~/filtered_search/services/recent_searches_service_error';
import AccessorUtilities from '~/lib/utils/accessor';

useLocalStorageSpy();

describe('RecentSearchesService', () => {
  let service;

  beforeEach(() => {
    service = new RecentSearchesService();
    localStorage.removeItem(service.localStorageKey);
  });

  describe('fetch', () => {
    beforeEach(() => {
      jest.spyOn(RecentSearchesService, 'isAvailable').mockReturnValue(true);
    });

    it('should default to empty array', (done) => {
      const fetchItemsPromise = service.fetch();

      fetchItemsPromise
        .then((items) => {
          expect(items).toEqual([]);
        })
        .then(done)
        .catch(done.fail);
    });

    it('should reject when unable to parse', (done) => {
      jest.spyOn(localStorage, 'getItem').mockReturnValue('fail');
      const fetchItemsPromise = service.fetch();

      fetchItemsPromise
        .then(done.fail)
        .catch((error) => {
          expect(error).toEqual(expect.any(SyntaxError));
        })
        .then(done)
        .catch(done.fail);
    });

    it('should reject when service is unavailable', (done) => {
      RecentSearchesService.isAvailable.mockReturnValue(false);

      service
        .fetch()
        .then(done.fail)
        .catch((error) => {
          expect(error).toEqual(expect.any(Error));
        })
        .then(done)
        .catch(done.fail);
    });

    it('should return items from localStorage', (done) => {
      jest.spyOn(localStorage, 'getItem').mockReturnValue('["foo", "bar"]');
      const fetchItemsPromise = service.fetch();

      fetchItemsPromise
        .then((items) => {
          expect(items).toEqual(['foo', 'bar']);
        })
        .then(done)
        .catch(done.fail);
    });

    describe('if .isAvailable returns `false`', () => {
      beforeEach(() => {
        RecentSearchesService.isAvailable.mockReturnValue(false);

        jest.spyOn(Storage.prototype, 'getItem').mockImplementation(() => {});
      });

      it('should not call .getItem', (done) => {
        RecentSearchesService.prototype
          .fetch()
          .then(done.fail)
          .catch((err) => {
            expect(err).toEqual(new RecentSearchesServiceError());
            expect(localStorage.getItem).not.toHaveBeenCalled();
          })
          .then(done)
          .catch(done.fail);
      });
    });
  });

  describe('setRecentSearches', () => {
    beforeEach(() => {
      jest.spyOn(RecentSearchesService, 'isAvailable').mockReturnValue(true);
    });

    it('should save things in localStorage', () => {
      jest.spyOn(localStorage, 'setItem');
      const items = ['foo', 'bar'];
      service.save(items);

      expect(localStorage.setItem).toHaveBeenCalledWith(expect.any(String), JSON.stringify(items));
    });
  });

  describe('save', () => {
    beforeEach(() => {
      jest.spyOn(localStorage, 'setItem');
      jest.spyOn(RecentSearchesService, 'isAvailable').mockImplementation(() => {});
    });

    describe('if .isAvailable returns `true`', () => {
      const searchesString = 'searchesString';
      const localStorageKey = 'localStorageKey';
      const recentSearchesService = {
        localStorageKey,
      };

      beforeEach(() => {
        RecentSearchesService.isAvailable.mockReturnValue(true);

        jest.spyOn(JSON, 'stringify').mockReturnValue(searchesString);
      });

      it('should call .setItem', () => {
        RecentSearchesService.prototype.save.call(recentSearchesService);

        expect(localStorage.setItem).toHaveBeenCalledWith(localStorageKey, searchesString);
      });
    });

    describe('if .isAvailable returns `false`', () => {
      beforeEach(() => {
        RecentSearchesService.isAvailable.mockReturnValue(false);
      });

      it('should not call .setItem', () => {
        RecentSearchesService.prototype.save();

        expect(localStorage.setItem).not.toHaveBeenCalled();
      });
    });
  });

  describe('isAvailable', () => {
    let isAvailable;

    beforeEach(() => {
      jest.spyOn(AccessorUtilities, 'isLocalStorageAccessSafe');

      isAvailable = RecentSearchesService.isAvailable();
    });

    it('should call .isLocalStorageAccessSafe', () => {
      expect(AccessorUtilities.isLocalStorageAccessSafe).toHaveBeenCalled();
    });

    it('should return a boolean', () => {
      expect(typeof isAvailable).toBe('boolean');
    });
  });
});
