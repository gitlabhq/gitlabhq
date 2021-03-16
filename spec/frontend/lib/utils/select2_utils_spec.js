import MockAdapter from 'axios-mock-adapter';
import $ from 'jquery';
import { setHTMLFixture } from 'helpers/fixtures';
import waitForPromises from 'helpers/wait_for_promises';
import axios from '~/lib/utils/axios_utils';
import { select2AxiosTransport } from '~/lib/utils/select2_utils';

import 'select2/select2';

const TEST_URL = '/test/api/url';
const TEST_SEARCH_DATA = { extraSearch: 'test' };
const TEST_DATA = [{ id: 1 }];
const TEST_SEARCH = 'FOO';

describe('lib/utils/select2_utils', () => {
  let mock;
  let resultsSpy;

  beforeEach(() => {
    setHTMLFixture('<div><input id="root" /></div>');

    mock = new MockAdapter(axios);

    resultsSpy = jest.fn().mockReturnValue({ results: [] });
  });

  afterEach(() => {
    mock.restore();
  });

  const setupSelect2 = (input) => {
    input.select2({
      ajax: {
        url: TEST_URL,
        quietMillis: 250,
        transport: select2AxiosTransport,
        data(search, page) {
          return {
            search,
            page,
            ...TEST_SEARCH_DATA,
          };
        },
        results: resultsSpy,
      },
    });
  };

  const setupSelect2AndSearch = async () => {
    const $input = $('#root');

    setupSelect2($input);

    $input.select2('search', TEST_SEARCH);

    jest.runOnlyPendingTimers();
    await waitForPromises();
  };

  describe('select2AxiosTransport', () => {
    it('uses axios to make request', async () => {
      // setup mock response
      const replySpy = jest.fn();
      mock.onGet(TEST_URL).reply((...args) => replySpy(...args));

      await setupSelect2AndSearch();

      expect(replySpy).toHaveBeenCalledWith(
        expect.objectContaining({
          url: TEST_URL,
          method: 'get',
          params: {
            page: 1,
            search: TEST_SEARCH,
            ...TEST_SEARCH_DATA,
          },
        }),
      );
    });

    it.each`
      headers                                | pagination
      ${{}}                                  | ${{ more: false }}
      ${{ 'X-PAGE': '1', 'x-next-page': 2 }} | ${{ more: true }}
    `(
      'passes results and pagination to results callback, with headers=$headers',
      async ({ headers, pagination }) => {
        mock.onGet(TEST_URL).reply(200, TEST_DATA, headers);

        await setupSelect2AndSearch();

        expect(resultsSpy).toHaveBeenCalledWith(
          { results: TEST_DATA, pagination },
          1,
          expect.anything(),
        );
      },
    );
  });
});
