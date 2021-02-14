import { commitActionTypes } from '~/ide/constants';
import createDiff from '~/ide/lib/create_diff';
import createFileDiff from '~/ide/lib/create_file_diff';
import {
  createNewFile,
  createUpdatedFile,
  createDeletedFile,
  createMovedFile,
  createEntries,
} from '../file_helpers';

const PATH_FOO = 'test/foo.md';
const PATH_BAR = 'test/bar.md';
const PATH_ZED = 'test/zed.md';
const PATH_LOREM = 'test/lipsum/nested/lorem.md';
const PATH_IPSUM = 'test/lipsum/ipsum.md';
const TEXT = `Lorem ipsum dolor sit amet,
consectetur adipiscing elit.
Morbi ex dolor, euismod nec rutrum nec, egestas at ligula.
Praesent scelerisque ut nisi eu eleifend.
Suspendisse potenti.
`;
const LINES = TEXT.trim().split('\n');

const joinDiffs = (...patches) => patches.join('');

describe('IDE lib/create_diff', () => {
  it('with created files, generates patch', () => {
    const changedFiles = [createNewFile(PATH_FOO, TEXT), createNewFile(PATH_BAR, '')];
    const result = createDiff({ changedFiles });

    expect(result).toEqual({
      patch: joinDiffs(
        createFileDiff(changedFiles[0], commitActionTypes.create),
        createFileDiff(changedFiles[1], commitActionTypes.create),
      ),
      toDelete: [],
    });
  });

  it('with deleted files, adds to delete', () => {
    const changedFiles = [createDeletedFile(PATH_FOO, TEXT), createDeletedFile(PATH_BAR, '')];

    const result = createDiff({ changedFiles });

    expect(result).toEqual({
      patch: '',
      toDelete: [PATH_FOO, PATH_BAR],
    });
  });

  it('with updated files, generates patch', () => {
    const changedFiles = [createUpdatedFile(PATH_FOO, TEXT, 'A change approaches!')];

    const result = createDiff({ changedFiles });

    expect(result).toEqual({
      patch: createFileDiff(changedFiles[0], commitActionTypes.update),
      toDelete: [],
    });
  });

  it('with files in both staged and changed, prefer changed', () => {
    const changedFiles = [
      createUpdatedFile(PATH_FOO, TEXT, 'Do a change!'),
      createDeletedFile(PATH_LOREM),
    ];

    const result = createDiff({
      changedFiles,
      stagedFiles: [createUpdatedFile(PATH_LOREM, TEXT, ''), createDeletedFile(PATH_FOO, TEXT)],
    });

    expect(result).toEqual({
      patch: createFileDiff(changedFiles[0], commitActionTypes.update),
      toDelete: [PATH_LOREM],
    });
  });

  it('with file created in staging and deleted in changed, do nothing', () => {
    const result = createDiff({
      changedFiles: [createDeletedFile(PATH_FOO)],
      stagedFiles: [createNewFile(PATH_FOO, TEXT)],
    });

    expect(result).toEqual({
      patch: '',
      toDelete: [],
    });
  });

  it('with file deleted in both staged and changed, delete', () => {
    const result = createDiff({
      changedFiles: [createDeletedFile(PATH_LOREM)],
      stagedFiles: [createDeletedFile(PATH_LOREM)],
    });

    expect(result).toEqual({
      patch: '',
      toDelete: [PATH_LOREM],
    });
  });

  it('with file moved, create and delete', () => {
    const changedFiles = [createMovedFile(PATH_BAR, PATH_FOO, TEXT)];

    const result = createDiff({
      changedFiles,
      stagedFiles: [createDeletedFile(PATH_FOO)],
    });

    expect(result).toEqual({
      patch: createFileDiff(changedFiles[0], commitActionTypes.create),
      toDelete: [PATH_FOO],
    });
  });

  it('with file moved and no content, move', () => {
    const changedFiles = [createMovedFile(PATH_BAR, PATH_FOO)];

    const result = createDiff({
      changedFiles,
      stagedFiles: [createDeletedFile(PATH_FOO)],
    });

    expect(result).toEqual({
      patch: createFileDiff(changedFiles[0], commitActionTypes.move),
      toDelete: [],
    });
  });

  it('creates a well formatted patch', () => {
    const changedFiles = [
      createMovedFile(PATH_BAR, PATH_FOO),
      createDeletedFile(PATH_ZED),
      createNewFile(PATH_LOREM, TEXT),
      createUpdatedFile(PATH_IPSUM, TEXT, "That's all folks!"),
    ];

    const expectedPatch = `diff --git "a/${PATH_FOO}" "b/${PATH_BAR}"
rename from ${PATH_FOO}
rename to ${PATH_BAR}
diff --git "a/${PATH_LOREM}" "b/${PATH_LOREM}"
new file mode 100644
--- /dev/null
+++ b/${PATH_LOREM}
@@ -0,0 +1,${LINES.length} @@
${LINES.map((line) => `+${line}`).join('\n')}
diff --git "a/${PATH_IPSUM}" "b/${PATH_IPSUM}"
--- a/${PATH_IPSUM}
+++ b/${PATH_IPSUM}
@@ -1,${LINES.length} +1,1 @@
${LINES.map((line) => `-${line}`).join('\n')}
+That's all folks!
\\ No newline at end of file
`;

    const result = createDiff({ changedFiles });

    expect(result).toEqual({
      patch: expectedPatch,
      toDelete: [PATH_ZED],
    });
  });

  it('deletes deleted parent directories', () => {
    const deletedFiles = ['foo/bar/zed/test.md', 'foo/bar/zed/test2.md'];
    const entries = deletedFiles.reduce((acc, path) => Object.assign(acc, createEntries(path)), {});
    const allDeleted = [...deletedFiles, 'foo/bar/zed', 'foo/bar'];
    allDeleted.forEach((path) => {
      entries[path].deleted = true;
    });
    const changedFiles = deletedFiles.map((x) => entries[x]);

    const result = createDiff({ changedFiles, entries });

    expect(result).toEqual({
      patch: '',
      toDelete: allDeleted,
    });
  });
});
