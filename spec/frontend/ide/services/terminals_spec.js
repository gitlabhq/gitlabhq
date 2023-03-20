import MockAdapter from 'axios-mock-adapter';
import * as terminalService from '~/ide/services/terminals';
import axios from '~/lib/utils/axios_utils';
import { HTTP_STATUS_OK } from '~/lib/utils/http_status';

const TEST_PROJECT_PATH = 'lorem/ipsum/dolar';
const TEST_BRANCH = 'ref';

describe('~/ide/services/terminals', () => {
  let axiosSpy;
  let mock;

  beforeEach(() => {
    axiosSpy = jest.fn().mockReturnValue([HTTP_STATUS_OK, {}]);

    mock = new MockAdapter(axios);
    mock.onPost(/.*/).reply((...args) => axiosSpy(...args));
  });

  afterEach(() => {
    mock.restore();
  });

  it.each`
    method           | relativeUrlRoot | url
    ${'checkConfig'} | ${''}           | ${`/${TEST_PROJECT_PATH}/ide_terminals/check_config`}
    ${'checkConfig'} | ${'/'}          | ${`/${TEST_PROJECT_PATH}/ide_terminals/check_config`}
    ${'checkConfig'} | ${'/gitlabbin'} | ${`/gitlabbin/${TEST_PROJECT_PATH}/ide_terminals/check_config`}
    ${'create'}      | ${''}           | ${`/${TEST_PROJECT_PATH}/ide_terminals`}
    ${'create'}      | ${'/'}          | ${`/${TEST_PROJECT_PATH}/ide_terminals`}
    ${'create'}      | ${'/gitlabbin'} | ${`/gitlabbin/${TEST_PROJECT_PATH}/ide_terminals`}
  `(
    'when $method called, posts request to $url (relative_url_root=$relativeUrlRoot)',
    async ({ method, url, relativeUrlRoot }) => {
      gon.relative_url_root = relativeUrlRoot;

      await terminalService[method](TEST_PROJECT_PATH, TEST_BRANCH);

      expect(axiosSpy).toHaveBeenCalledWith(
        expect.objectContaining({
          data: JSON.stringify({
            branch: TEST_BRANCH,
            format: 'json',
          }),
          url,
        }),
      );
    },
  );
});
