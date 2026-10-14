import { getBrowseFilesPath } from '~/projects/commits/utils/browse_files_path';

describe('getBrowseFilesPath', () => {
  const projectRootPath = '/gitlab-org/gitlab-shell';
  const commitSha = '8e3336548a7aa36b7cae362fbd8c694793ecc110';

  it.each(['', null, undefined])(
    'returns the repository tree path when currentPath is %p',
    (currentPath) => {
      expect(getBrowseFilesPath({ projectRootPath, commitSha, currentPath })).toBe(
        `${projectRootPath}/-/tree/${commitSha}`,
      );
    },
  );

  it('returns the blob path when currentPath is set', () => {
    expect(
      getBrowseFilesPath({ projectRootPath, commitSha, currentPath: 'app/models/user.rb' }),
    ).toBe(`${projectRootPath}/-/blob/${commitSha}/app/models/user.rb`);
  });

  it('escapes special characters in the file path', () => {
    expect(getBrowseFilesPath({ projectRootPath, commitSha, currentPath: 'app/file #1.rb' })).toBe(
      `${projectRootPath}/-/blob/${commitSha}/app/file%20%231.rb`,
    );
  });
});
