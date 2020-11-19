import MockAdapter from 'axios-mock-adapter';
import axios from '~/lib/utils/axios_utils';
import httpStatus from '~/lib/utils/http_status';

import resolvers from '~/ci_lint/graphql/resolvers';
import { mockLintResponse } from '../mock_data';

describe('~/ci_lint/graphql/resolvers', () => {
  let mock;

  beforeEach(() => {
    mock = new MockAdapter(axios);
  });

  afterEach(() => {
    mock.restore();
  });

  describe('Mutation', () => {
    describe('lintCI', () => {
      const endpoint = '/ci/lint';

      beforeEach(() => {
        mock.onPost(endpoint).reply(httpStatus.OK, mockLintResponse);
      });

      it('resolves lint data with type names', async () => {
        const result = resolvers.Mutation.lintCI(null, {
          endpoint,
          content: 'content',
          dry_run: true,
        });

        await expect(result).resolves.toMatchSnapshot();
      });
    });
  });
});
