import { showBlameButton, isUsingLfs } from '~/repository/utils/storage_info_utils';

describe('storage_info_utils', () => {
  describe('showBlameButton', () => {
    it('returns true when file is not externally stored', () => {
      const blobInfo = {
        storedExternally: false,
        externalStorage: null,
      };

      expect(showBlameButton(blobInfo)).toBe(true);
    });

    it('returns false when file is externally stored', () => {
      const blobInfo = {
        storedExternally: true,
        externalStorage: 'something',
      };

      expect(showBlameButton(blobInfo)).toBe(false);
    });

    it('returns false when file is stored in LFS', () => {
      const blobInfo = {
        storedExternally: true,
        externalStorage: 'lfs',
      };

      expect(showBlameButton(blobInfo)).toBe(false);
    });
  });

  describe('isUsingLfs', () => {
    it('returns true when file is stored externally in LFS', () => {
      const blobInfo = {
        storedExternally: true,
        externalStorage: 'lfs',
      };

      expect(isUsingLfs(blobInfo)).toBe(true);
    });

    it('returns false when file is not stored externally', () => {
      const blobInfo = {
        storedExternally: false,
        externalStorage: null,
      };

      expect(isUsingLfs(blobInfo)).toBe(false);
    });

    it('returns false when file is stored externally but not in LFS', () => {
      const blobInfo = {
        storedExternally: true,
        externalStorage: 'other',
      };

      expect(isUsingLfs(blobInfo)).toBe(false);
    });
  });

  // Testing edge cases
  describe('edge cases', () => {
    it('handles undefined blobInfo properties', () => {
      const blobInfo = {
        storedExternally: undefined,
        externalStorage: undefined,
      };

      expect(showBlameButton(blobInfo)).toBe(true);
      expect(isUsingLfs(blobInfo)).toBe(false);
    });

    it('handles empty blobInfo object', () => {
      const blobInfo = {};

      expect(showBlameButton(blobInfo)).toBe(true);
      expect(isUsingLfs(blobInfo)).toBe(false);
    });
  });
});
