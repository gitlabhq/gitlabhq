import Api from '~/api';
import { mockProjectPath, mockDefaultBranch, mockCiConfigPath, mockCiYml } from '../mock_data';

import { resolvers } from '~/pipeline_editor/graphql/resolvers';

jest.mock('~/api', () => {
  return {
    getRawFile: jest.fn(),
  };
});

describe('~/pipeline_editor/graphql/resolvers', () => {
  describe('Query', () => {
    describe('blobContent', () => {
      beforeEach(() => {
        Api.getRawFile.mockResolvedValue({
          data: mockCiYml,
        });
      });

      afterEach(() => {
        Api.getRawFile.mockReset();
      });

      it('resolves lint data with type names', async () => {
        const result = resolvers.Query.blobContent(null, {
          projectPath: mockProjectPath,
          path: mockCiConfigPath,
          ref: mockDefaultBranch,
        });

        expect(Api.getRawFile).toHaveBeenCalledWith(mockProjectPath, mockCiConfigPath, {
          ref: mockDefaultBranch,
        });

        // eslint-disable-next-line no-underscore-dangle
        expect(result.__typename).toBe('BlobContent');
        await expect(result.rawData).resolves.toBe(mockCiYml);
      });
    });
  });
});
