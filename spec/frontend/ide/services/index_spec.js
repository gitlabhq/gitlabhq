import services from '~/ide/services';
import Api from '~/api';

jest.mock('~/api');

const TEST_PROJECT_ID = 'alice/wonderland';
const TEST_BRANCH = 'master-patch-123';
const TEST_COMMIT_SHA = '123456789';

describe('IDE services', () => {
  describe('commit', () => {
    let payload;

    beforeEach(() => {
      payload = {
        branch: TEST_BRANCH,
        commit_message: 'Hello world',
        actions: [],
        start_sha: TEST_COMMIT_SHA,
      };

      Api.commitMultiple.mockReturnValue(Promise.resolve());
    });

    it('should commit', () => {
      services.commit(TEST_PROJECT_ID, payload);

      expect(Api.commitMultiple).toHaveBeenCalledWith(TEST_PROJECT_ID, payload);
    });
  });
});
