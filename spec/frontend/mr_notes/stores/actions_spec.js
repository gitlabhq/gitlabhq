import MockAdapter from 'axios-mock-adapter';
import axios from '~/lib/utils/axios_utils';
import { HTTP_STATUS_INTERNAL_SERVER_ERROR, HTTP_STATUS_OK } from '~/lib/utils/http_status';
import { createStore } from '~/mr_notes/stores';

describe('MR Notes Mutator Actions', () => {
  let store;

  beforeEach(() => {
    store = createStore();
  });

  describe('setEndpoints', () => {
    it('sets endpoints', async () => {
      const endpoints = { endpointA: 'a' };

      await store.dispatch('setEndpoints', endpoints);

      expect(store.state.page.endpoints).toEqual(endpoints);
    });
  });

  describe('fetchMrMetadata', () => {
    const mrMetadata = { meta: true, data: 'foo' };
    const metadata = 'metadata';
    const endpoints = { metadata };
    let mock;

    beforeEach(async () => {
      await store.dispatch('setEndpoints', endpoints);

      mock = new MockAdapter(axios);

      mock.onGet(metadata).reply(HTTP_STATUS_OK, mrMetadata);
    });

    afterEach(() => {
      mock.restore();
    });

    it('should fetch the data from the API', async () => {
      await store.dispatch('fetchMrMetadata');

      await axios.waitForAll();

      expect(mock.history.get).toHaveLength(1);
      expect(mock.history.get[0].url).toBe(metadata);
    });

    it('should set the fetched data into state', async () => {
      await store.dispatch('fetchMrMetadata');

      expect(store.state.page.mrMetadata).toEqual(mrMetadata);
    });

    it('should set failedToLoadMetadata flag when request fails', async () => {
      mock.onGet(metadata).reply(HTTP_STATUS_INTERNAL_SERVER_ERROR);

      await store.dispatch('fetchMrMetadata');

      expect(store.state.page.failedToLoadMetadata).toBe(true);
    });
  });
});
