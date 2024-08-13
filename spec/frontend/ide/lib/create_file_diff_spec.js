import { commitActionTypes } from '~/ide/constants';
import createFileDiff from '~/ide/lib/create_file_diff';
import {
  createUpdatedFile,
  createNewFile,
  createMovedFile,
  createDeletedFile,
} from '../file_helpers';

const PATH = 'test/numbers.md';
const PATH_FOO = 'test/foo.md';
const TEXT_LINE_COUNT = 100;
const TEXT = Array(TEXT_LINE_COUNT)
  .fill(0)
  .map((_, idx) => `${idx + 1}`)
  .join('\n');

// eslint-disable-next-line max-params
const spliceLines = (content, lineNumber, deleteCount = 0, newLines = []) => {
  const lines = content.split('\n');
  lines.splice(lineNumber, deleteCount, ...newLines);
  return lines.join('\n');
};

const mapLines = (content, mapFn) => content.split('\n').map(mapFn).join('\n');

describe('IDE lib/create_file_diff', () => {
  it('returns empty string with "garbage" action', () => {
    const result = createFileDiff(createNewFile(PATH, ''), 'garbage');

    expect(result).toBe('');
  });

  it('preserves ending whitespace in file', () => {
    const oldContent = spliceLines(TEXT, 99, 1, ['100 ']);
    const newContent = spliceLines(oldContent, 99, 0, ['Lorem', 'Ipsum']);
    const expected = `
 99
+Lorem
+Ipsum
 100 `;

    const result = createFileDiff(
      createUpdatedFile(PATH, oldContent, newContent),
      commitActionTypes.update,
    );

    expect(result).toContain(expected);
  });

  describe('with "create" action', () => {
    const expectedHead = `diff --git "a/${PATH}" "b/${PATH}"
new file mode 100644`;

    const expectedChunkHead = (lineCount) => `--- /dev/null
+++ b/${PATH}
@@ -0,0 +1,${lineCount} @@`;

    it('with empty file, does not include diff body', () => {
      const result = createFileDiff(createNewFile(PATH, ''), commitActionTypes.create);

      expect(result).toBe(`${expectedHead}\n`);
    });

    it('with single line, includes diff body', () => {
      const result = createFileDiff(createNewFile(PATH, '\n'), commitActionTypes.create);

      expect(result).toBe(`${expectedHead}
${expectedChunkHead(1)}
+
`);
    });

    it('without newline, includes no newline comment', () => {
      const result = createFileDiff(createNewFile(PATH, 'Lorem ipsum'), commitActionTypes.create);

      expect(result).toBe(`${expectedHead}
${expectedChunkHead(1)}
+Lorem ipsum
\\ No newline at end of file
`);
    });

    it('with content, includes diff body', () => {
      const content = `${TEXT}\n`;
      const result = createFileDiff(createNewFile(PATH, content), commitActionTypes.create);

      expect(result).toBe(`${expectedHead}
${expectedChunkHead(TEXT_LINE_COUNT)}
${mapLines(TEXT, (line) => `+${line}`)}
`);
    });
  });

  describe('with "delete" action', () => {
    const expectedHead = `diff --git "a/${PATH}" "b/${PATH}"
deleted file mode 100644`;

    const expectedChunkHead = (lineCount) => `--- a/${PATH}
+++ /dev/null
@@ -1,${lineCount} +0,0 @@`;

    it('with empty file, does not include diff body', () => {
      const result = createFileDiff(createDeletedFile(PATH, ''), commitActionTypes.delete);

      expect(result).toBe(`${expectedHead}\n`);
    });

    it('with content, includes diff body', () => {
      const content = `${TEXT}\n`;
      const result = createFileDiff(createDeletedFile(PATH, content), commitActionTypes.delete);

      expect(result).toBe(`${expectedHead}
${expectedChunkHead(TEXT_LINE_COUNT)}
${mapLines(TEXT, (line) => `-${line}`)}
`);
    });
  });

  describe('with "update" action', () => {
    it('includes diff body', () => {
      const oldContent = `${TEXT}\n`;
      const newContent = `${spliceLines(TEXT, 50, 3, ['Lorem'])}\n`;

      const result = createFileDiff(
        createUpdatedFile(PATH, oldContent, newContent),
        commitActionTypes.update,
      );

      expect(result).toBe(`diff --git "a/${PATH}" "b/${PATH}"
--- a/${PATH}
+++ b/${PATH}
@@ -47,11 +47,9 @@
 47
 48
 49
 50
-51
-52
-53
+Lorem
 54
 55
 56
 57
`);
    });
  });

  describe('with "move" action', () => {
    it('returns rename head', () => {
      const result = createFileDiff(createMovedFile(PATH, PATH_FOO), commitActionTypes.move);

      expect(result).toBe(`diff --git "a/${PATH_FOO}" "b/${PATH}"
rename from ${PATH_FOO}
rename to ${PATH}
`);
    });
  });
});
