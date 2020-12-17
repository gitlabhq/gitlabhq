import { prepareRawDiffFile } from '~/diffs/utils/diff_file';

function getDiffFiles() {
  return [
    {
      blob: {
        id: 'C0473471',
      },
      file_hash: 'ABC', // This file is just a normal file
      file_identifier_hash: 'ABC1',
    },
    {
      blob: {
        id: 'C0473472',
      },
      file_hash: 'DEF', // This file replaces a symlink
      file_identifier_hash: 'DEF1',
      a_mode: '0',
      b_mode: '0755',
    },
    {
      blob: {
        id: 'C0473473',
      },
      file_hash: 'DEF', // This symlink is replaced by a file
      file_identifier_hash: 'DEF2',
      a_mode: '120000',
      b_mode: '0',
    },
    {
      blob: {
        id: 'C0473474',
      },
      file_hash: 'GHI', // This symlink replaces a file
      file_identifier_hash: 'GHI1',
      a_mode: '0',
      b_mode: '120000',
    },
    {
      blob: {
        id: 'C0473475',
      },
      file_hash: 'GHI', // This file is replaced by a symlink
      file_identifier_hash: 'GHI2',
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
      ${0}      | ${'8dcd585e-a421-4dab-a04e-6f88c81b7b4c'}
      ${1}      | ${'3f178b78-392b-44a4-bd7d-5d6192208a97'}
      ${2}      | ${'3d9e1354-cddf-4a11-8234-f0413521b2e5'}
      ${3}      | ${'460f005b-d29d-43c1-9a08-099a7c7f08de'}
      ${4}      | ${'d8c89733-6ce1-4455-ae3d-f8aad6ee99f9'}
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
  });
});
