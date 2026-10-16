import { testApolloLink } from 'helpers/test_apollo_link';
import { backgroundRequestLink } from '~/lib/apollo/background_request_link';
import {
  BACKGROUND_REQUEST_HEADER,
  IDLE_THRESHOLD_MS,
  setLastActivityAtForTestsOnly,
} from '~/lib/utils/user_activity';

describe('~/lib/apollo/background_request_link', () => {
  const defaultHeaders = { Authorization: 'foo' };

  const getHeaders = async () => {
    const operation = await testApolloLink(backgroundRequestLink, {
      context: { headers: defaultHeaders },
    });

    return operation.getContext().headers;
  };

  describe('when the user is active', () => {
    beforeEach(() => {
      setLastActivityAtForTestsOnly(performance.now());
    });

    it('does not add the background request header', async () => {
      expect(await getHeaders()).toEqual(defaultHeaders);
    });
  });

  describe('when the user is idle', () => {
    beforeEach(() => {
      setLastActivityAtForTestsOnly(performance.now() - IDLE_THRESHOLD_MS);
    });

    it('adds the background request header', async () => {
      expect(await getHeaders()).toEqual({ ...defaultHeaders, [BACKGROUND_REQUEST_HEADER]: '1' });
    });
  });
});
