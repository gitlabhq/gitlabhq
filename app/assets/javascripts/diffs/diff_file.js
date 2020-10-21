import { DIFF_FILE_SYMLINK_MODE, DIFF_FILE_DELETED_MODE } from './constants';

function fileSymlinkInformation(file, fileList) {
  const duplicates = fileList.filter(iteratedFile => iteratedFile.file_hash === file.file_hash);
  const includesSymlink = duplicates.some(iteratedFile => {
    return [iteratedFile.a_mode, iteratedFile.b_mode].includes(DIFF_FILE_SYMLINK_MODE);
  });
  const brokenSymlinkScenario = duplicates.length > 1 && includesSymlink;

  return (
    brokenSymlinkScenario && {
      replaced: file.b_mode === DIFF_FILE_DELETED_MODE,
      wasSymbolic: file.a_mode === DIFF_FILE_SYMLINK_MODE,
      isSymbolic: file.b_mode === DIFF_FILE_SYMLINK_MODE,
      wasReal: ![DIFF_FILE_SYMLINK_MODE, DIFF_FILE_DELETED_MODE].includes(file.a_mode),
      isReal: ![DIFF_FILE_SYMLINK_MODE, DIFF_FILE_DELETED_MODE].includes(file.b_mode),
    }
  );
}

function collapsed(file) {
  const viewer = file.viewer || {};

  return {
    automaticallyCollapsed: viewer.automaticallyCollapsed || viewer.collapsed || false,
  };
}

export function prepareRawDiffFile({ file, allFiles }) {
  Object.assign(file, {
    brokenSymlink: fileSymlinkInformation(file, allFiles),
    viewer: {
      ...file.viewer,
      ...collapsed(file),
    },
  });

  return file;
}
