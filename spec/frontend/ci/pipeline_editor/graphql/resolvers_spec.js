import MockAdapter from 'axios-mock-adapter';
import axios from '~/lib/utils/axios_utils';
import { HTTP_STATUS_OK } from '~/lib/utils/http_status';
import { resolvers } from '~/ci/pipeline_editor/graphql/resolvers';
import { mockLintResponse } from '../mock_data';

jest.mock('~/api', () => {
  return {
    getRawFile: jest.fn(),
  };
});

describe('~/ci/pipeline_editor/graphql/resolvers', () => {
  describe('Mutation', () => {
    describe('lintCI', () => {
      let mock;
      let result;

      const endpoint = '/ci/lint';

      beforeEach(async () => {
        mock = new MockAdapter(axios);
        mock.onPost(endpoint).reply(HTTP_STATUS_OK, mockLintResponse);

        result = await resolvers.Mutation.lintCI(null, {
          endpoint,
          content: 'content',
          dry_run: true,
        });
      });

      afterEach(() => {
        mock.restore();
      });

      /* eslint-disable no-underscore-dangle */
      it('lint data has correct type names', () => {
        expect(result.__typename).toBe('CiLintContent');

        expect(result.jobs[0].__typename).toBe('CiLintJob');
        expect(result.jobs[1].__typename).toBe('CiLintJob');

        expect(result.jobs[1].only.__typename).toBe('CiLintJobOnlyPolicy');
      });
      /* eslint-enable no-underscore-dangle */

      it('lint data is as expected', () => {
        expect(result).toMatchSnapshot();
      });
    });
  });
});
