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
        start_sha: undefined,
      };

      Api.createBranch.mockReturnValue(Promise.resolve());
      Api.commitMultiple.mockReturnValue(Promise.resolve());
    });

    describe.each`
      startSha           | shouldCreateBranch
      ${undefined}       | ${false}
      ${TEST_COMMIT_SHA} | ${true}
    `('when start_sha is $startSha', ({ startSha, shouldCreateBranch }) => {
      beforeEach(() => {
        payload.start_sha = startSha;

        return services.commit(TEST_PROJECT_ID, payload);
      });

      if (shouldCreateBranch) {
        it('should create branch', () => {
          expect(Api.createBranch).toHaveBeenCalledWith(TEST_PROJECT_ID, {
            ref: TEST_COMMIT_SHA,
            branch: TEST_BRANCH,
          });
        });
      } else {
        it('should not create branch', () => {
          expect(Api.createBranch).not.toHaveBeenCalled();
        });
      }

      it('should commit', () => {
        expect(Api.commitMultiple).toHaveBeenCalledWith(TEST_PROJECT_ID, payload);
      });
    });
  });
});
