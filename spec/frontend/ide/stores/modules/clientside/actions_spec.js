import MockAdapter from 'axios-mock-adapter';
import testAction from 'helpers/vuex_action_helper';
import { TEST_HOST } from 'helpers/test_constants';
import axios from '~/lib/utils/axios_utils';
import * as actions from '~/ide/stores/modules/clientside/actions';

const TEST_PROJECT_URL = `${TEST_HOST}/lorem/ipsum`;
const TEST_USAGE_URL = `${TEST_PROJECT_URL}/usage_ping/web_ide_clientside_preview`;

describe('IDE store module clientside actions', () => {
  let rootGetters;
  let mock;

  beforeEach(() => {
    rootGetters = {
      currentProject: {
        web_url: TEST_PROJECT_URL,
      },
    };
    mock = new MockAdapter(axios);
  });

  afterEach(() => {
    mock.restore();
  });

  describe('pingUsage', () => {
    it('posts to usage endpoint', done => {
      const usageSpy = jest.fn(() => [200]);

      mock.onPost(TEST_USAGE_URL).reply(() => usageSpy());

      testAction(actions.pingUsage, null, rootGetters, [], [], () => {
        expect(usageSpy).toHaveBeenCalled();
        done();
      });
    });
  });
});
