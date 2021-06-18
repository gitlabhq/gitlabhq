import MockAdapter from 'axios-mock-adapter';
import { dismiss } from '~/feature_highlight/feature_highlight_helper';
import createFlash from '~/flash';
import axios from '~/lib/utils/axios_utils';
import httpStatusCodes from '~/lib/utils/http_status';

jest.mock('~/flash');

describe('feature highlight helper', () => {
  describe('dismiss', () => {
    let mockAxios;
    const endpoint = '/-/callouts/dismiss';
    const highlightId = '123';
    const { CREATED, INTERNAL_SERVER_ERROR } = httpStatusCodes;

    beforeEach(() => {
      mockAxios = new MockAdapter(axios);
    });

    afterEach(() => {
      mockAxios.reset();
    });

    it('calls persistent dismissal endpoint with highlightId', async () => {
      mockAxios.onPost(endpoint, { feature_name: highlightId }).replyOnce(CREATED);

      await expect(dismiss(endpoint, highlightId)).resolves.toEqual(expect.anything());
    });

    it('triggers flash when dismiss request fails', async () => {
      mockAxios.onPost(endpoint, { feature_name: highlightId }).replyOnce(INTERNAL_SERVER_ERROR);

      await dismiss(endpoint, highlightId);

      expect(createFlash).toHaveBeenCalledWith({
        message:
          'An error occurred while dismissing the feature highlight. Refresh the page and try dismissing again.',
      });
    });
  });
});
