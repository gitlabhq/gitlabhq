import { createPinia, setActivePinia } from 'pinia';
import { useFileBrowser } from '~/diffs/stores/file_browser';
import { getCookie, setCookie } from '~/lib/utils/common_utils';
import { FILE_BROWSER_VISIBLE } from '~/diffs/constants';

describe('FileBrowser store', () => {
  beforeEach(() => {
    setActivePinia(createPinia());
  });

  describe('browser visibility', () => {
    beforeEach(() => {
      window.document.cookie = '';
    });

    it('is visible by default', () => {
      expect(useFileBrowser().fileBrowserVisible).toBe(true);
    });

    it('#setFileBrowserVisibility', () => {
      useFileBrowser().setFileBrowserVisibility(false);
      expect(useFileBrowser().fileBrowserVisible).toBe(false);
    });

    it('#toggleFileBrowserVisibility', () => {
      useFileBrowser().toggleFileBrowserVisibility();
      expect(useFileBrowser().fileBrowserVisible).toBe(false);
      expect(getCookie(FILE_BROWSER_VISIBLE)).toBe('false');
    });

    it('#initFileBrowserVisibility', () => {
      setCookie(FILE_BROWSER_VISIBLE, false);
      useFileBrowser().initFileBrowserVisibility();
      expect(useFileBrowser().fileBrowserVisible).toBe(false);
    });
  });

  describe('browser drawer visibility', () => {
    it('is hidden by default', () => {
      expect(useFileBrowser().fileBrowserDrawerVisible).toBe(false);
    });

    it('#setFileBrowserDrawerVisibility', () => {
      useFileBrowser().setFileBrowserDrawerVisibility(true);
      expect(useFileBrowser().fileBrowserDrawerVisible).toBe(true);
    });

    it('#toggleFileBrowserDrawerVisibility', () => {
      useFileBrowser().toggleFileBrowserDrawerVisibility();
      expect(useFileBrowser().fileBrowserDrawerVisible).toBe(true);
    });
  });
});
