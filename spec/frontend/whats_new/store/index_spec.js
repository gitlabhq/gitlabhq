import MockAdapter from 'axios-mock-adapter';
import { createTestingPinia } from '@pinia/testing';
import waitForPromises from 'helpers/wait_for_promises';
import { createAlert } from '~/alert';
import axios from '~/lib/utils/axios_utils';
import { HTTP_STATUS_INTERNAL_SERVER_ERROR, HTTP_STATUS_OK } from '~/lib/utils/http_status';
import { useWhatsNew } from '~/whats_new/store';

jest.mock('~/alert');

describe('whats new store', () => {
  let store;

  beforeEach(() => {
    createTestingPinia({ stubActions: false });
    store = useWhatsNew();
  });

  describe('closeDrawer', () => {
    it('sets open to false', () => {
      store.open = true;
      store.closeDrawer();
      expect(store.open).toBe(false);
    });
  });

  describe('openDrawer', () => {
    it('sets open to true', () => {
      store.openDrawer();
      expect(store.open).toBe(true);
    });
  });

  describe('fetchItems', () => {
    let axiosMock;

    const mockDefaultResponse = () =>
      axiosMock
        .onGet('/-/whats_new')
        .replyOnce(HTTP_STATUS_OK, [{ title: 'Whats New Drawer', url: 'www.url.com' }], {
          'x-next-page': '2',
        });

    beforeAll(() => {
      axiosMock = new MockAdapter(axios);
    });

    afterEach(() => {
      axiosMock.reset();
    });

    afterAll(() => {
      axiosMock.restore();
    });

    it("doesn't require arguments", async () => {
      axiosMock.onGet('/-/whats_new').replyOnce(HTTP_STATUS_OK, [{ title: 'GitLab Stories' }]);

      store.fetchItems();
      await waitForPromises();

      expect(store.features).toEqual([
        { releaseHeading: true, release: undefined },
        { title: 'GitLab Stories' },
      ]);
    });

    it('passes arguments', async () => {
      axiosMock.onGet('/-/whats_new').replyOnce(HTTP_STATUS_OK, [{ title: 'GitLab Stories' }]);

      store.fetchItems({ page: 8, versionDigest: 42 });
      await waitForPromises();

      expect(axiosMock.history.get[0].params).toEqual({ page: 8, v: 42 });
      expect(store.features).toEqual([
        { releaseHeading: true, release: undefined },
        { title: 'GitLab Stories' },
      ]);
    });

    it('if already fetching, does not fetch', async () => {
      store.fetching = true;

      await store.fetchItems();

      expect(axiosMock.history.get).toHaveLength(0);
    });

    it('shows an alert and resets state when the request errors', async () => {
      axiosMock.onGet('/-/whats_new').replyOnce(HTTP_STATUS_INTERNAL_SERVER_ERROR);
      store.pageInfo = { nextPage: 2 };

      await store.fetchItems();

      expect(createAlert).toHaveBeenCalledWith(
        expect.objectContaining({
          message: expect.stringContaining("Failed to load What's new features"),
          captureError: true,
        }),
      );
      expect(store.features).toEqual([]);
      expect(store.fetching).toBe(false);
      expect(store.pageInfo).toEqual({ nextPage: null });
    });

    it('should set fetching, add features, and set page info', async () => {
      mockDefaultResponse();

      expect(store.fetching).toBe(false);

      const fetchPromise = store.fetchItems();
      expect(store.fetching).toBe(true);

      await fetchPromise;

      expect(store.features).toEqual([
        { releaseHeading: true, release: undefined },
        { title: 'Whats New Drawer', url: 'www.url.com' },
      ]);
      expect(store.pageInfo).toEqual({ nextPage: 2 });
      expect(store.fetching).toBe(false);
    });

    it('appends to existing features', async () => {
      mockDefaultResponse();

      store.features = ['existing item'];

      await store.fetchItems();

      expect(store.features).toEqual([
        'existing item',
        { releaseHeading: true, release: undefined },
        { title: 'Whats New Drawer', url: 'www.url.com' },
      ]);
    });
  });

  describe('setReadArticles', () => {
    it('sets readArticles', () => {
      store.setReadArticles([1]);
      expect(store.readArticles).toEqual([1]);
    });
  });
});
