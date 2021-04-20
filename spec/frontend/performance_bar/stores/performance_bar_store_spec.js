import PerformanceBarStore from '~/performance_bar/stores/performance_bar_store';

describe('PerformanceBarStore', () => {
  describe('truncateUrl', () => {
    let store;
    const findUrl = (id) => store.findRequest(id).truncatedUrl;

    beforeEach(() => {
      store = new PerformanceBarStore();
    });

    it('ignores trailing slashes', () => {
      store.addRequest('id', 'https://gitlab.com/');
      expect(findUrl('id')).toEqual('gitlab.com');
    });

    it('keeps the last two components of the path when the last component is numeric', () => {
      store.addRequest('id', 'https://gitlab.com/gitlab-org/gitlab-foss/-/merge_requests/1');
      expect(findUrl('id')).toEqual('merge_requests/1');
    });

    it('uses the last component of the path', () => {
      store.addRequest(
        'id',
        'https://gitlab.com/gitlab-org/gitlab-foss/-/merge_requests/1.json?serializer=widget',
      );
      expect(findUrl('id')).toEqual('1.json?serializer=widget');
    });

    it('keeps query components', () => {
      store.addRequest('id', 'http://localhost:3001/h5bp/html5-boilerplate/?param');
      expect(findUrl('id')).toEqual('html5-boilerplate?param');
    });

    it('keeps components when query contains a slash', () => {
      store.addRequest('id', 'http://localhost:3001/h5bp/html5-boilerplate?trunc/ated');
      expect(findUrl('id')).toEqual('html5-boilerplate?trunc/ated');
    });

    it('ignores fragments', () => {
      store.addRequest('id', 'http://localhost:3001/h5bp/html5-boilerplate/#frag/ment');
      expect(findUrl('id')).toEqual('html5-boilerplate');
    });
  });

  describe('setRequestDetailsData', () => {
    let store;

    beforeEach(() => {
      store = new PerformanceBarStore();
    });

    it('updates correctly specific details', () => {
      store.addRequest('id', 'https://gitlab.com/');
      store.setRequestDetailsData('id', 'test', {
        calls: 123,
      });

      expect(store.findRequest('id').details.test.calls).toEqual(123);
    });
  });

  describe('canTrackRequest', () => {
    let store;

    beforeEach(() => {
      store = new PerformanceBarStore();
    });

    it('limits to 10 requests for GraphQL', () => {
      expect(store.canTrackRequest('https://gitlab.com/api/graphql')).toBe(true);

      store.addRequest('0', 'https://gitlab.com/api/graphql');
      store.addRequest('1', 'https://gitlab.com/api/graphql');
      store.addRequest('2', 'https://gitlab.com/api/graphql');
      store.addRequest('3', 'https://gitlab.com/api/graphql');
      store.addRequest('4', 'https://gitlab.com/api/graphql');
      store.addRequest('5', 'https://gitlab.com/api/graphql');
      store.addRequest('6', 'https://gitlab.com/api/graphql');
      store.addRequest('7', 'https://gitlab.com/api/graphql');
      store.addRequest('8', 'https://gitlab.com/api/graphql');

      expect(store.canTrackRequest('https://gitlab.com/api/graphql')).toBe(true);

      store.addRequest('9', 'https://gitlab.com/api/graphql');

      expect(store.canTrackRequest('https://gitlab.com/api/graphql')).toBe(false);
    });

    it('limits to 2 requests for all other URLs', () => {
      expect(store.canTrackRequest('https://gitlab.com/api/v4/users/1')).toBe(true);

      store.addRequest('a', 'https://gitlab.com/api/v4/users/1');

      expect(store.canTrackRequest('https://gitlab.com/api/v4/users/1')).toBe(true);

      store.addRequest('b', 'https://gitlab.com/api/v4/users/1');

      expect(store.canTrackRequest('https://gitlab.com/api/v4/users/1')).toBe(false);
    });
  });
});
