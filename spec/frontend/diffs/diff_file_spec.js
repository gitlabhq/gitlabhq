import { prepareRawDiffFile } from '~/diffs/diff_file';

const DIFF_FILES = [
  {
    file_hash: 'ABC', // This file is just a normal file
  },
  {
    file_hash: 'DEF', // This file replaces a symlink
    a_mode: '0',
    b_mode: '0755',
  },
  {
    file_hash: 'DEF', // This symlink is replaced by a file
    a_mode: '120000',
    b_mode: '0',
  },
  {
    file_hash: 'GHI', // This symlink replaces a file
    a_mode: '0',
    b_mode: '120000',
  },
  {
    file_hash: 'GHI', // This file is replaced by a symlink
    a_mode: '0755',
    b_mode: '0',
  },
];

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
          file: DIFF_FILES[fileIndex],
          allFiles: DIFF_FILES,
        });

        expect(preppedRaw.brokenSymlink).toStrictEqual(brokenSymlink);
      },
    );
  });
});
