import MockAdapter from 'axios-mock-adapter';
import { dismiss } from '~/feature_highlight/feature_highlight_helper';
import { createAlert } from '~/alert';
import axios from '~/lib/utils/axios_utils';
import { HTTP_STATUS_CREATED, HTTP_STATUS_INTERNAL_SERVER_ERROR } from '~/lib/utils/http_status';

jest.mock('~/alert');

describe('feature highlight helper', () => {
  describe('dismiss', () => {
    let mockAxios;
    const endpoint = '/-/callouts/dismiss';
    const highlightId = '123';

    beforeEach(() => {
      mockAxios = new MockAdapter(axios);
    });

    afterEach(() => {
      mockAxios.reset();
    });

    it('calls persistent dismissal endpoint with highlightId', async () => {
      mockAxios.onPost(endpoint, { feature_name: highlightId }).replyOnce(HTTP_STATUS_CREATED);

      await expect(dismiss(endpoint, highlightId)).resolves.toEqual(expect.anything());
    });

    it('triggers an alert when dismiss request fails', async () => {
      mockAxios
        .onPost(endpoint, { feature_name: highlightId })
        .replyOnce(HTTP_STATUS_INTERNAL_SERVER_ERROR);

      await dismiss(endpoint, highlightId);

      expect(createAlert).toHaveBeenCalledWith({
        message:
          'An error occurred while dismissing the feature highlight. Refresh the page and try dismissing again.',
      });
    });
  });
});
