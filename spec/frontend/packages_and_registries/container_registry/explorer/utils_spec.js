import {
  getImageName,
  timeTilRun,
  getNextPageParams,
  getPreviousPageParams,
  getPageParams,
} from '~/packages_and_registries/container_registry/explorer/utils';

describe('Container registry utilities', () => {
  describe('getImageName', () => {
    it('returns name when present', () => {
      const result = getImageName({ name: 'foo' });

      expect(result).toBe('foo');
    });

    it('returns project path when name is empty', () => {
      const result = getImageName({ name: '', project: { path: 'foo' } });

      expect(result).toBe('foo');
    });
  });

  describe('timeTilRun', () => {
    beforeEach(() => {
      jest.spyOn(Date, 'now').mockImplementation(() => new Date('2063-04-04T00:42:00Z').getTime());
    });

    it('should return a human readable time', () => {
      const result = timeTilRun('2063-04-08T01:44:03Z');

      expect(result).toBe('4 days');
    });

    it('should return an empty string with null times', () => {
      const result = timeTilRun(null);

      expect(result).toBe('');
    });
  });

  describe('getNextPageParams', () => {
    it('should return the next page params with the provided cursor', () => {
      const cursor = 'abc123';
      expect(getNextPageParams(cursor)).toEqual({
        after: cursor,
        first: 10,
      });
    });
  });

  describe('getPreviousPageParams', () => {
    it('should return the previous page params with the provided cursor', () => {
      const cursor = 'abc123';
      expect(getPreviousPageParams(cursor)).toEqual({
        first: null,
        before: cursor,
        last: 10,
      });
    });
  });

  describe('getPageParams', () => {
    it('should return the previous page params if before cursor is available', () => {
      const pageInfo = { before: 'abc123' };
      expect(getPageParams(pageInfo)).toEqual({
        first: null,
        before: pageInfo.before,
        last: 10,
      });
    });

    it('should return the next page params if after cursor is available', () => {
      const pageInfo = { after: 'abc123' };
      expect(getPageParams(pageInfo)).toEqual({
        after: pageInfo.after,
        first: 10,
      });
    });

    it('should return an empty object if both before and after cursors are not available', () => {
      const pageInfo = {};
      expect(getPageParams(pageInfo)).toEqual({});
    });
  });
});
