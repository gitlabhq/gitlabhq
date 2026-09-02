import MockAdapter from 'axios-mock-adapter';
import axios from '~/lib/utils/axios_utils';
import { HTTP_STATUS_OK } from '~/lib/utils/http_status';
import MRWidgetService from '~/vue_merge_request_widget/services/mr_widget_service';

describe('MRWidgetService', () => {
  let mock;

  beforeEach(() => {
    window.gl = {
      mrWidgetData: {
        merge_request_cached_widget_path: '/cached',
        merge_request_widget_path: '/widget',
      },
    };

    mock = new MockAdapter(axios);
    mock.onGet('/cached').reply(HTTP_STATUS_OK, { cached: true });
    mock.onGet('/widget').reply(HTTP_STATUS_OK, { widget: true });
  });

  afterEach(() => {
    mock.restore();
    delete window.gl;
  });

  describe('fetchInitialData', () => {
    it('shares one round trip between overlapping callers, then fetches again', async () => {
      await Promise.all([MRWidgetService.fetchInitialData(), MRWidgetService.fetchInitialData()]);

      expect(mock.history.get).toHaveLength(2);

      await MRWidgetService.fetchInitialData();

      expect(mock.history.get).toHaveLength(4);
    });
  });
});
