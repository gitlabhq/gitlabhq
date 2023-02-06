import MockAdapter from 'axios-mock-adapter';
import {
  getRenderedMarkdown,
  splitDocument,
} from '~/vue_shared/components/markdown_drawer/utils/fetch';
import axios from '~/lib/utils/axios_utils';
import { HTTP_STATUS_INTERNAL_SERVER_ERROR, HTTP_STATUS_OK } from '~/lib/utils/http_status';
import {
  MOCK_HTML,
  MOCK_DRAWER_DATA,
  MOCK_DRAWER_DATA_ERROR,
  MOCK_TABLE_DATA_BEFORE,
  MOCK_HTML_DATA_AFTER,
} from '../mock_data';

describe('utils/fetch', () => {
  let mock;

  afterEach(() => {
    mock.restore();
  });

  describe.each`
    axiosMock                                                 | type         | toExpect
    ${{ code: HTTP_STATUS_OK, res: MOCK_HTML }}               | ${'success'} | ${MOCK_DRAWER_DATA}
    ${{ code: HTTP_STATUS_INTERNAL_SERVER_ERROR, res: null }} | ${'error'}   | ${MOCK_DRAWER_DATA_ERROR}
  `('process markdown data', ({ axiosMock, type, toExpect }) => {
    describe(`if api fetch responds with ${type}`, () => {
      beforeEach(() => {
        mock = new MockAdapter(axios);
        mock.onGet().reply(axiosMock.code, axiosMock.res);
      });
      it(`should update drawer correctly`, async () => {
        expect(await getRenderedMarkdown('/any/path')).toStrictEqual(toExpect);
      });
    });
  });

  describe('splitDocument', () => {
    it(`should update tables correctly`, () => {
      expect(splitDocument(MOCK_TABLE_DATA_BEFORE)).toStrictEqual(MOCK_HTML_DATA_AFTER);
    });
  });
});
