import { createTestingPinia } from '@pinia/testing';
import { useFileTreeBrowserVisibility } from '~/repository/stores/file_tree_browser_visibility';
import { FILE_TREE_BROWSER_VISIBILITY } from '~/repository/constants';
import { useLocalStorageSpy } from 'helpers/local_storage_helper';

describe('useFileTreeVisibility', () => {
  useLocalStorageSpy();

  beforeEach(() => {
    createTestingPinia({
      stubActions: false,
    });
  });

  afterEach(() => {
    localStorage.clear();
  });

  describe('initialization', () => {
    it('initializes with stored value from localStorage when available', () => {
      localStorage.setItem(FILE_TREE_BROWSER_VISIBILITY, 'true');
      useFileTreeBrowserVisibility().initFileTreeVisibility();

      expect(useFileTreeBrowserVisibility().fileTreeBrowserVisible).toBe(true);
    });
  });

  describe('setVisible', () => {
    it('updates visibility state and localStorage', () => {
      useFileTreeBrowserVisibility().setFileTreeVisibility(true);

      expect(useFileTreeBrowserVisibility().fileTreeBrowserVisible).toBe(true);
      expect(localStorage.setItem).toHaveBeenCalledWith(FILE_TREE_BROWSER_VISIBILITY, 'true');
    });

    it('can hide the file tree', () => {
      useFileTreeBrowserVisibility().setFileTreeVisibility(false);

      expect(useFileTreeBrowserVisibility().fileTreeBrowserVisible).toBe(false);
      expect(localStorage.setItem).toHaveBeenCalledWith(FILE_TREE_BROWSER_VISIBILITY, 'false');
    });
  });

  describe('toggle', () => {
    it('toggles visibility from false to true', () => {
      useFileTreeBrowserVisibility().setFileTreeVisibility(false);
      useFileTreeBrowserVisibility().toggleFileTreeVisibility();

      expect(useFileTreeBrowserVisibility().fileTreeBrowserVisible).toBe(true);
      expect(localStorage.setItem).toHaveBeenCalledWith(FILE_TREE_BROWSER_VISIBILITY, 'true');
    });

    it('toggles visibility from true to false', () => {
      useFileTreeBrowserVisibility().setFileTreeVisibility(true);
      useFileTreeBrowserVisibility().toggleFileTreeVisibility();

      expect(useFileTreeBrowserVisibility().fileTreeBrowserVisible).toBe(false);
      expect(localStorage.setItem).toHaveBeenCalledWith(FILE_TREE_BROWSER_VISIBILITY, 'false');
    });
  });
});
