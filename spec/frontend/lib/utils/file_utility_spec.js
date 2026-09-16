import { readFileAsDataURL } from '~/lib/utils/file_utility';

describe('File utilities', () => {
  describe('readFileAsDataURL', () => {
    it('reads a file and returns its output as a data url', () => {
      const file = new File(['foo'], 'foo.png', { type: 'image/png' });

      return readFileAsDataURL(file).then((contents) => {
        expect(contents).toBe('data:image/png;base64,Zm9v');
      });
    });

    // Without an error listener the promise stays pending forever, so a caller
    // awaiting an unreadable file would hang rather than fail.
    it('rejects when the file cannot be read', async () => {
      const error = new Error('unreadable');

      jest.spyOn(FileReader.prototype, 'readAsDataURL').mockImplementation(function mockRead() {
        Object.defineProperty(this, 'error', { value: error, configurable: true });
        this.dispatchEvent(new Event('error'));
      });

      await expect(readFileAsDataURL(new File([''], 'foo.png'))).rejects.toBe(error);
    });
  });
});
