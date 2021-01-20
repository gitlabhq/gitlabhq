import {
  designDeletionError,
  designUploadSkippedWarning,
} from '~/design_management/utils/error_messages';

const mockFilenames = (n) =>
  Array(n)
    .fill(0)
    .map((_, i) => ({ filename: `${i + 1}.jpg` }));

describe('Error message', () => {
  describe('designDeletionError', () => {
    const singularMsg = 'Could not archive a design. Please try again.';
    const pluralMsg = 'Could not archive designs. Please try again.';

    describe('when [singular=true]', () => {
      it.each([[undefined], [true]])('uses singular grammar', (singularOption) => {
        expect(designDeletionError({ singular: singularOption })).toEqual(singularMsg);
      });
    });

    describe('when [singular=false]', () => {
      it('uses plural grammar', () => {
        expect(designDeletionError({ singular: false })).toEqual(pluralMsg);
      });
    });
  });

  describe.each([
    [[], [], null],
    [mockFilenames(1), mockFilenames(1), 'Upload skipped. 1.jpg did not change.'],
    [
      mockFilenames(2),
      mockFilenames(2),
      'Upload skipped. The designs you tried uploading did not change.',
    ],
    [
      mockFilenames(2),
      mockFilenames(1),
      'Upload skipped. Some of the designs you tried uploading did not change: 1.jpg.',
    ],
    [
      mockFilenames(6),
      mockFilenames(5),
      'Upload skipped. Some of the designs you tried uploading did not change: 1.jpg, 2.jpg, 3.jpg, 4.jpg, 5.jpg.',
    ],
    [
      mockFilenames(7),
      mockFilenames(6),
      'Upload skipped. Some of the designs you tried uploading did not change: 1.jpg, 2.jpg, 3.jpg, 4.jpg, 5.jpg, and 1 more.',
    ],
    [
      mockFilenames(8),
      mockFilenames(7),
      'Upload skipped. Some of the designs you tried uploading did not change: 1.jpg, 2.jpg, 3.jpg, 4.jpg, 5.jpg, and 2 more.',
    ],
  ])('designUploadSkippedWarning', (uploadedFiles, skippedFiles, expected) => {
    it('returns expected warning message', () => {
      expect(designUploadSkippedWarning(uploadedFiles, skippedFiles)).toBe(expected);
    });
  });
});
