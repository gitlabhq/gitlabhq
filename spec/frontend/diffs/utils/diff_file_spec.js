import {
  prepareRawDiffFile,
  getShortShaFromFile,
  stats,
  isNotDiffable,
} from '~/diffs/utils/diff_file';
import { diffViewerModes } from '~/ide/constants';
import mockDiffFile from '../mock_data/diff_file';

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
      mockDiffFile,
      {
        changed: 1024,
        percent: 100,
        classes: 'gl-text-green-600',
        sign: '+',
        text: '+1.00 KiB (+100%)',
        valid: true,
      },
    ];
    const negativeChange = [
      'computed the correct states from a file with a negative size change',
      {
        ...mockDiffFile,
        new_size: 0,
        old_size: 1024,
      },
      {
        changed: -1024,
        percent: -100,
        classes: 'gl-text-red-500',
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
});
