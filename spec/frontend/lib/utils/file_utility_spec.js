import { readFileAsDataURL } from '~/lib/utils/file_utility';

describe('File utilities', () => {
  describe('readFileAsDataURL', () => {
    it('reads a file and returns its output as a data url', () => {
      const file = new File(['foo'], 'foo.png', { type: 'image/png' });

      return readFileAsDataURL(file).then((contents) => {
        expect(contents).toBe('data:image/png;base64,Zm9v');
      });
    });
  });
});
