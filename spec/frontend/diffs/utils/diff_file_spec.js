import { prepareRawDiffFile } from '~/diffs/utils/diff_file';

function getDiffFiles() {
  return [
    {
      file_hash: 'ABC', // This file is just a normal file
      file_identifier_hash: 'ABC1',
      content_sha: 'C047347',
    },
    {
      file_hash: 'DEF', // This file replaces a symlink
      file_identifier_hash: 'DEF1',
      content_sha: 'C047347',
      a_mode: '0',
      b_mode: '0755',
    },
    {
      file_hash: 'DEF', // This symlink is replaced by a file
      file_identifier_hash: 'DEF2',
      content_sha: 'C047347',
      a_mode: '120000',
      b_mode: '0',
    },
    {
      file_hash: 'GHI', // This symlink replaces a file
      file_identifier_hash: 'GHI1',
      content_sha: 'C047347',
      a_mode: '0',
      b_mode: '120000',
    },
    {
      file_hash: 'GHI', // This file is replaced by a symlink
      file_identifier_hash: 'GHI2',
      content_sha: 'C047347',
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
      ${0}      | ${'e075da30-4ec7-4e1c-a505-fe0fb0efe2d8'}
      ${1}      | ${'5ab05419-123e-4d18-8454-0b8c3d9f3f91'}
      ${2}      | ${'94eb6bba-575c-4504-bd8e-5d302364d31e'}
      ${3}      | ${'06d669b2-29b7-4f47-9731-33fc38a8db61'}
      ${4}      | ${'edd3e8f9-07f9-4647-8171-544c72e5a175'}
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

    it('does not set the id property if the file is missing a `content_sha`', () => {
      const fileMissingContentSha = { ...files[0] };

      delete fileMissingContentSha.content_sha;

      const preppedFile = prepareRawDiffFile({
        file: fileMissingContentSha,
        allFiles: files,
      });

      expect(preppedFile).not.toHaveProp('id');
    });
  });
});
