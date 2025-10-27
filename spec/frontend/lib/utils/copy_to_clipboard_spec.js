import { copyToClipboard } from '~/lib/utils/copy_to_clipboard';

describe('copyToClipboard', () => {
  let mockWriteText;

  beforeEach(() => {
    document.execCommand = jest.fn().mockReturnValue(true);
    mockWriteText = jest.spyOn(navigator.clipboard, 'writeText');
  });

  afterEach(() => {
    jest.restoreAllMocks();
  });

  describe('in secure context (HTTPS/localhost)', () => {
    beforeEach(() => {
      window.isSecureContext = true;
    });

    it('should use navigator.clipboard.writeText', async () => {
      mockWriteText.mockResolvedValue();

      await copyToClipboard('test text');

      expect(mockWriteText).toHaveBeenCalledWith('test text');
      expect(document.execCommand).not.toHaveBeenCalled();
    });

    it('should reject when navigator.clipboard.writeText fails', async () => {
      const error = new Error('Clipboard write failed');
      mockWriteText.mockRejectedValue(error);

      await expect(copyToClipboard('test text')).rejects.toThrow('Clipboard write failed');
    });
  });

  describe('in non-secure context (HTTP)', () => {
    beforeEach(() => {
      window.isSecureContext = false;
      document.execCommand.mockReturnValue(true);
    });

    it('should use execCommand', async () => {
      await copyToClipboard('test text');

      expect(mockWriteText).not.toHaveBeenCalled();
      expect(document.execCommand).toHaveBeenCalledWith('copy');
    });

    it('should create an invisible textarea', async () => {
      jest.spyOn(document, 'createElement');

      await copyToClipboard('test text');

      expect(document.createElement).toHaveBeenCalledWith('textarea');

      const textarea = document.createElement.mock.results[0].value;

      expect(textarea.value).toBe('test text');
      expect(textarea.style).toMatchObject({
        position: 'absolute',
        left: '-9999px',
        top: '0px',
      });
      expect(textarea.getAttribute('readonly')).toBe('');
    });

    it('should append textarea to default container (document.body)', async () => {
      const appendChildSpy = jest.spyOn(document.body, 'appendChild');
      const removeChildSpy = jest.spyOn(document.body, 'removeChild');

      await copyToClipboard('test text');

      expect(appendChildSpy).toHaveBeenCalled();
      expect(removeChildSpy).toHaveBeenCalled();
    });

    it('should append textarea to custom container', async () => {
      const container = document.createElement('div');

      const appendChildSpy = jest.spyOn(container, 'appendChild');
      const removeChildSpy = jest.spyOn(container, 'removeChild');

      await copyToClipboard('test text', container);

      expect(appendChildSpy).toHaveBeenCalled();
      expect(removeChildSpy).toHaveBeenCalled();
    });

    it('should call select and setSelectionRange on textarea', async () => {
      const textarea = document.createElement('textarea');
      jest.spyOn(textarea, 'select');
      jest.spyOn(textarea, 'setSelectionRange');

      jest.spyOn(document, 'createElement').mockImplementation(() => {
        return textarea;
      });

      await copyToClipboard('test text');

      expect(textarea.select).toHaveBeenCalled();
      expect(textarea.setSelectionRange).toHaveBeenCalledWith(0, 9); // 'test text'.length = 9
    });

    it('should resolve promise when execCommand returns true', async () => {
      document.execCommand.mockReturnValue(true);

      await expect(copyToClipboard('test text')).resolves.toBeUndefined();
    });

    it('should reject promise when execCommand returns false', async () => {
      document.execCommand.mockReturnValue(false);

      await expect(copyToClipboard('test text')).rejects.toEqual(new Error('Copy command failed'));
    });

    it('should reject promise when execCommand throws an error', async () => {
      const error = new Error('execCommand failed');
      document.execCommand.mockImplementation(() => {
        throw error;
      });

      await expect(copyToClipboard('test text')).rejects.toThrow('execCommand failed');
    });

    it('should remove textarea from DOM even when execCommand fails', async () => {
      document.execCommand.mockReturnValue(false);
      const removeChildSpy = jest.spyOn(document.body, 'removeChild');

      try {
        await copyToClipboard('test text');
      } catch (err) {
        // Expected to reject
      }

      expect(removeChildSpy).toHaveBeenCalled();
    });

    it('should remove textarea from DOM even when execCommand throws', async () => {
      document.execCommand.mockImplementation(() => {
        throw new Error('Failed');
      });
      const removeChildSpy = jest.spyOn(document.body, 'removeChild');

      try {
        await copyToClipboard('test text');
      } catch (err) {
        // Expected to reject
      }

      expect(removeChildSpy).toHaveBeenCalled();
    });
  });
});
