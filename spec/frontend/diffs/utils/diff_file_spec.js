import {
  prepareRawDiffFile,
  getShortShaFromFile,
  stats,
  isNotDiffable,
  match,
  countLinesInBetween,
  findClosestMatchLine,
  lineExists,
} from '~/diffs/utils/diff_file';
import { diffViewerModes } from '~/ide/constants';
import { getDiffFileMock } from '../mock_data/diff_file';

function getDiffFiles() {
  const loadFull = 'namespace/project/-/merge_requests/12345/diff_for_path?file_identifier=abc';

  return [
    {
      blob: {
        id: 'C0473471',
      },
      file_hash: 'ABC', // This file is just a normal file
      file_identifier_hash: 'ABC1',
      load_collapsed_diff_url: loadFull,
    },
    {
      blob: {
        id: 'C0473472',
      },
      file_hash: 'DEF', // This file replaces a symlink
      file_identifier_hash: 'DEF1',
      load_collapsed_diff_url: loadFull,
      a_mode: '0',
      b_mode: '0755',
    },
    {
      blob: {
        id: 'C0473473',
      },
      file_hash: 'DEF', // This symlink is replaced by a file
      file_identifier_hash: 'DEF2',
      load_collapsed_diff_url: loadFull,
      a_mode: '120000',
      b_mode: '0',
    },
    {
      blob: {
        id: 'C0473474',
      },
      file_hash: 'GHI', // This symlink replaces a file
      file_identifier_hash: 'GHI1',
      load_collapsed_diff_url: loadFull,
      a_mode: '0',
      b_mode: '120000',
    },
    {
      blob: {
        id: 'C0473475',
      },
      file_hash: 'GHI', // This file is replaced by a symlink
      file_identifier_hash: 'GHI2',
      load_collapsed_diff_url: loadFull,
      a_mode: '0755',
      b_mode: '0',
    },
  ];
}
// eslint-disable-next-line max-params
function makeBrokenSymlinkObject(replaced, wasSymbolic, isSymbolic, wasReal, isReal) {
  return {
    replaced,
    wasSymbolic,
    isSymbolic,
    wasReal,
    isReal,
  };
}

describe('diff_file utilities', () => {
  describe('prepareRawDiffFile', () => {
    let files;

    beforeEach(() => {
      files = getDiffFiles();
    });

    it.each`
      fileIndex | description                               | brokenSymlink
      ${0}      | ${'a file that is not symlink-adjacent'}  | ${false}
      ${1}      | ${'a file that replaces a symlink'}       | ${makeBrokenSymlinkObject(false, false, false, false, true)}
      ${2}      | ${'a symlink that is replaced by a file'} | ${makeBrokenSymlinkObject(true, true, false, false, false)}
      ${3}      | ${'a symlink that replaces a file'}       | ${makeBrokenSymlinkObject(false, false, true, false, false)}
      ${4}      | ${'a file that is replaced by a symlink'} | ${makeBrokenSymlinkObject(true, false, false, true, false)}
    `(
      'properly marks $description with the correct .brokenSymlink value',
      ({ fileIndex, brokenSymlink }) => {
        const preppedRaw = prepareRawDiffFile({
          file: files[fileIndex],
          allFiles: files,
        });

        expect(preppedRaw.brokenSymlink).toStrictEqual(brokenSymlink);
      },
    );

    it.each`
      fileIndex | id
      ${0}      | ${'68296a4f-f1c7-445a-bd0e-6e3b02c4eec0'}
      ${1}      | ${'051c9bb8-cdba-4eb7-b8d1-508906e6d8ba'}
      ${2}      | ${'ed3d53d5-5da0-412d-a3c6-7213f84e88d3'}
      ${3}      | ${'39d998dc-bc69-4b19-a6af-41e4369c2bd5'}
      ${4}      | ${'7072d115-ce39-423c-8346-9fcad58cd68e'}
    `('sets the file id properly { id: $id } on normal diff files', ({ fileIndex, id }) => {
      const preppedFile = prepareRawDiffFile({
        file: files[fileIndex],
        allFiles: files,
      });

      expect(preppedFile.id).toBe(id);
    });

    it('does not set the `id` property for metadata diff files', () => {
      const preppedFile = prepareRawDiffFile({
        file: files[0],
        allFiles: files,
        meta: true,
      });

      expect(preppedFile).not.toHaveProp('id');
    });

    it('does not set the id property if the file is missing a `blob.id`', () => {
      const fileMissingContentSha = { ...files[0] };

      delete fileMissingContentSha.blob.id;

      const preppedFile = prepareRawDiffFile({
        file: fileMissingContentSha,
        allFiles: files,
      });

      expect(preppedFile).not.toHaveProp('id');
    });

    it('does not set the id property if the file is missing a `load_collapsed_diff_url` property', () => {
      const fileMissingContentSha = { ...files[0] };

      delete fileMissingContentSha.load_collapsed_diff_url;

      const preppedFile = prepareRawDiffFile({
        file: fileMissingContentSha,
        allFiles: files,
      });

      expect(preppedFile).not.toHaveProp('id');
    });

    it.each`
      index
      ${null}
      ${undefined}
      ${-1}
      ${false}
      ${true}
      ${'idx'}
      ${'42'}
    `('does not set the order property if an invalid index ($index) is provided', ({ index }) => {
      const preppedFile = prepareRawDiffFile({
        file: files[0],
        allFiles: files,
        index,
      });

      /* expect.anything() doesn't match null or undefined */
      expect(preppedFile).toEqual(expect.not.objectContaining({ order: null }));
      expect(preppedFile).toEqual(expect.not.objectContaining({ order: undefined }));
      expect(preppedFile).toEqual(expect.not.objectContaining({ order: expect.anything() }));
    });

    it('sets the provided valid index to the order property', () => {
      const preppedFile = prepareRawDiffFile({
        file: files[0],
        allFiles: files,
        index: 42,
      });

      expect(preppedFile).toEqual(expect.objectContaining({ order: 42 }));
    });
  });

  describe('getShortShaFromFile', () => {
    it.each`
      response      | cs
      ${'12345678'} | ${'12345678abcdogcat'}
      ${null}       | ${undefined}
      ${'hidogcat'} | ${'hidogcatmorethings'}
    `('returns $response for a file with { content_sha: $cs }', ({ response, cs }) => {
      expect(getShortShaFromFile({ content_sha: cs })).toBe(response);
    });
  });

  describe('stats', () => {
    const noFile = [
      "returns empty stats when the file isn't provided",
      undefined,
      {
        text: '',
        percent: 0,
        changed: 0,
        classes: '',
        sign: '',
        valid: false,
      },
    ];
    const validFile = [
      'computes the correct stats from a file',
      getDiffFileMock(),
      {
        changed: 1024,
        percent: 100,
        classes: 'gl-text-success',
        sign: '+',
        text: '+1.00 KiB (+100%)',
        valid: true,
      },
    ];
    const negativeChange = [
      'computed the correct states from a file with a negative size change',
      {
        ...getDiffFileMock(),
        new_size: 0,
        old_size: 1024,
      },
      {
        changed: -1024,
        percent: -100,
        classes: 'gl-text-danger',
        sign: '',
        text: '-1.00 KiB (-100%)',
        valid: true,
      },
    ];

    it.each([noFile, validFile, negativeChange])('%s', (_, file, output) => {
      expect(stats(file)).toEqual(output);
    });
  });

  describe('isNotDiffable', () => {
    it.each`
      bool     | vw
      ${true}  | ${diffViewerModes.not_diffable}
      ${false} | ${diffViewerModes.text}
      ${false} | ${diffViewerModes.image}
    `('returns $bool when the viewer is $vw', ({ bool, vw }) => {
      expect(isNotDiffable({ viewer: { name: vw } })).toBe(bool);
    });

    it.each`
      file
      ${undefined}
      ${null}
      ${{}}
      ${{ viewer: undefined }}
      ${{ viewer: null }}
    `('reports `false` when the file is `$file`', ({ file }) => {
      expect(isNotDiffable(file)).toBe(false);
    });
  });

  describe('match', () => {
    const authorityFileId = '68296a4f-f1c7-445a-bd0e-6e3b02c4eec0';
    const fih = 'file_identifier_hash';
    const fihs = 'file identifier hashes';
    let authorityFile;

    beforeAll(() => {
      const files = getDiffFiles();

      authorityFile = prepareRawDiffFile({
        file: files[0],
        allFiles: files,
      });

      Object.freeze(authorityFile);
    });

    describe.each`
      mode           | comparisonFiles                                                    | keyName
      ${'universal'} | ${[{ [fih]: 'ABC1' }, { id: 'foo' }, { id: authorityFileId }]}     | ${'ids'}
      ${'mr'}        | ${[{ id: authorityFileId }, { [fih]: 'ABC2' }, { [fih]: 'ABC1' }]} | ${fihs}
    `('$mode mode', ({ mode, comparisonFiles, keyName }) => {
      it(`fails to match if files or ${keyName} aren't present`, () => {
        expect(match({ fileA: authorityFile, fileB: undefined, mode })).toBe(false);
        expect(match({ fileA: authorityFile, fileB: null, mode })).toBe(false);
        expect(match({ fileA: authorityFile, fileB: comparisonFiles[0], mode })).toBe(false);
      });

      it(`fails to match if the ${keyName} aren't the same`, () => {
        expect(match({ fileA: authorityFile, fileB: comparisonFiles[1], mode })).toBe(false);
      });

      it(`matches if the ${keyName} are the same`, () => {
        expect(match({ fileA: authorityFile, fileB: comparisonFiles[2], mode })).toBe(true);
      });
    });
  });

  describe('countLinesInBetween', () => {
    it('returns -1 for the first element', () => {
      expect(countLinesInBetween([], 0)).toBe(-1);
    });

    it('returns -1 for the last element', () => {
      expect(countLinesInBetween([{}, {}], 1)).toBe(-1);
    });

    it('calculates line difference for regular lines', () => {
      expect(
        countLinesInBetween([{ new_line: 1 }, { meta_data: { new_pos: 10 } }, { new_line: 10 }], 1),
      ).toBe(9);
    });

    it('calculates line difference for line sides', () => {
      expect(
        countLinesInBetween(
          [{ left: { new_line: 1 } }, { meta_data: { new_pos: 10 } }, { left: { new_line: 10 } }],
          1,
        ),
      ).toBe(9);
    });
  });

  describe('findClosestMatchLine', () => {
    const lines = [
      { meta_data: { new_pos: 5 } },
      { new_line: 5 },
      { meta_data: { new_pos: 10 } },
      { new_line: 10 },
      { meta_data: { new_pos: 20 } },
      { new_line: 20 },
      { new_line: 21 },
      { meta_data: { new_pos: 21 } },
    ];

    it('finds closest match line', () => {
      expect(findClosestMatchLine(lines, 15)).toBe(lines[4]);
    });

    it('returns first match line when outside of bounds', () => {
      expect(findClosestMatchLine(lines, 3)).toBe(lines[0]);
    });

    it('returns last match line when outside of bounds', () => {
      expect(findClosestMatchLine(lines, 25)).toBe(lines[lines.length - 1]);
    });
  });

  describe('lineExists', () => {
    it('returns true for existing line', () => {
      expect(lineExists([{ old_line: 15, new_line: 16 }], 15, 16)).toBe(true);
    });

    it('returns false for non-existing line', () => {
      expect(lineExists([{ old_line: 15, new_line: 16 }], 16, 16)).toBe(false);
    });
  });
});
