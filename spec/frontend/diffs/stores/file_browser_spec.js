import { createPinia, setActivePinia } from 'pinia';
import { useFileBrowser } from '~/diffs/stores/file_browser';
import { getCookie, setCookie } from '~/lib/utils/common_utils';
import {
  FILE_BROWSER_VISIBLE,
  TRACKING_CLICK_FILE_BROWSER_SETTING,
  TRACKING_FILE_BROWSER_LIST,
  TRACKING_FILE_BROWSER_TREE,
  TREE_LIST_STORAGE_KEY,
} from '~/diffs/constants';
import { queueRedisHllEvents } from '~/diffs/utils/queue_events';
import { linkTreeNodes, sortTree } from '~/ide/stores/utils';
import { generateTreeList } from '~/diffs/utils/tree_worker_utils';

jest.mock('~/diffs/utils/queue_events');
jest.mock('~/diffs/utils/tree_worker_utils');
jest.mock('~/ide/stores/utils');

describe('FileBrowser store', () => {
  beforeEach(() => {
    setActivePinia(createPinia());
  });

  describe('file tree', () => {
    const mockFiles = [
      { new_path: 'app/assets/file1.js', type: 'blob', parentPath: 'app/assets' },
      { new_path: 'app/assets/file2.js', type: 'blob', parentPath: 'app/assets' },
      { new_path: 'lib/file3.rb', type: 'blob', parentPath: 'lib' },
      { new_path: 'root_file.txt', type: 'blob', parentPath: '/' },
    ];

    const mockTreeEntries = {
      'app/assets/file1.js': mockFiles[0],
      'app/assets/file2.js': mockFiles[1],
      'lib/file3.rb': mockFiles[2],
      'root_file.txt': mockFiles[3],
      app: { type: 'tree', path: '/' },
      'app/assets': { type: 'tree', path: 'app/assets' },
      lib: { type: 'tree', path: 'lib' },
    };

    const mockTree = [{ path: 'app' }, { path: 'lib' }, { path: 'root_file.txt' }];
    const sortedTree = [mockTree[2], ...mockTree.slice(0, 2)];

    beforeEach(() => {
      localStorage.clear();

      generateTreeList.mockClear();
      sortTree.mockClear();
      queueRedisHllEvents.mockClear();

      generateTreeList.mockReturnValue({
        treeEntries: mockTreeEntries,
        tree: mockTree,
      });
      sortTree.mockImplementation(() => sortedTree);
      linkTreeNodes.mockImplementation((tree) => tree);
    });

    it('uses tree list by default', () => {
      expect(useFileBrowser().renderTreeList).toBe(true);
    });

    describe('setTreeData', () => {
      it('sets treeEntries and tree correctly, and sets isLoadingFileBrowser to false', () => {
        useFileBrowser().setTreeData(mockFiles);

        expect(useFileBrowser().treeEntries).toEqual(mockTreeEntries);
        expect(useFileBrowser().tree).toEqual(sortedTree);
        expect(useFileBrowser().isLoadingFileBrowser).toBe(false);
      });

      it('links tree nodes when shouldSort is false', () => {
        useFileBrowser().setTreeData(mockFiles, false);

        expect(useFileBrowser().tree).toEqual(mockTree);
      });
    });

    describe('setTreeOpen', () => {
      beforeEach(() => useFileBrowser().setTreeData(mockFiles));

      it('sets the opened state of a tree entry to true', () => {
        useFileBrowser().setTreeOpen('app/assets/file1.js', true);
        expect(useFileBrowser().treeEntries['app/assets/file1.js'].opened).toBe(true);
      });
    });

    describe('toggleTreeOpen', () => {
      beforeEach(() => useFileBrowser().setTreeData(mockFiles));

      it('toggles the opened state from false to true', () => {
        useFileBrowser().treeEntries['app/assets/file1.js'].opened = false;
        useFileBrowser().toggleTreeOpen('app/assets/file1.js');
        expect(useFileBrowser().treeEntries['app/assets/file1.js'].opened).toBe(true);
      });

      it('toggles the opened state from true to false', () => {
        useFileBrowser().treeEntries['app/assets/file1.js'].opened = true;
        useFileBrowser().toggleTreeOpen('app/assets/file1.js');
        expect(useFileBrowser().treeEntries['app/assets/file1.js'].opened).toBe(false);
      });
    });

    describe('markTreeEntriesLoaded', () => {
      it('does nothing if treeEntries is null', () => {
        useFileBrowser().treeEntries = null;
        useFileBrowser().markTreeEntriesLoaded(mockFiles);
        expect(useFileBrowser().treeEntries).toBe(null);
      });

      it('marks diffLoaded and diffLoading properties for loaded files', () => {
        useFileBrowser().setTreeData(mockFiles);
        const loadedFile = { new_path: 'app/assets/file1.js' };
        useFileBrowser().treeEntries[loadedFile.new_path].diffLoading = true;

        useFileBrowser().markTreeEntriesLoaded([loadedFile]);

        expect(useFileBrowser().treeEntries[loadedFile.new_path].diffLoaded).toBe(true);
        expect(useFileBrowser().treeEntries[loadedFile.new_path].diffLoading).toBe(false);
      });
    });

    describe('setTreeEntryDiffLoading', () => {
      it('does nothing if treeEntries is null', () => {
        useFileBrowser().treeEntries = null;
        useFileBrowser().setTreeEntryDiffLoading('app/assets/file1.js');
        expect(useFileBrowser().treeEntries).toBe(null);
      });

      it('sets diffLoading to true by default', () => {
        useFileBrowser().setTreeData(mockFiles);
        useFileBrowser().setTreeEntryDiffLoading('app/assets/file1.js');
        expect(useFileBrowser().treeEntries['app/assets/file1.js'].diffLoading).toBe(true);
      });

      it('sets diffLoading to false when specified', () => {
        useFileBrowser().setTreeData(mockFiles);
        useFileBrowser().treeEntries['app/assets/file1.js'].diffLoading = true;
        useFileBrowser().setTreeEntryDiffLoading('app/assets/file1.js', false);
        expect(useFileBrowser().treeEntries['app/assets/file1.js'].diffLoading).toBe(false);
      });
    });

    describe('initTreeList', () => {
      it('restores value from local storage', () => {
        localStorage.setItem(TREE_LIST_STORAGE_KEY, 'false');
        useFileBrowser().initTreeList();
        expect(useFileBrowser().renderTreeList).toBe(false);
      });
    });

    describe('setRenderTreeList', () => {
      it('sets renderTreeList and saves to localStorage', () => {
        useFileBrowser().setRenderTreeList(false);

        expect(useFileBrowser().renderTreeList).toBe(false);
        expect(localStorage.getItem(TREE_LIST_STORAGE_KEY)).toBe('false');
      });

      it('tracks the tree view event when value is true', () => {
        useFileBrowser().setRenderTreeList(true);

        expect(useFileBrowser().renderTreeList).toBe(true);
        expect(queueRedisHllEvents).toHaveBeenCalledWith([
          TRACKING_CLICK_FILE_BROWSER_SETTING,
          TRACKING_FILE_BROWSER_TREE,
        ]);
      });

      it('tracks the list view event when value is false', () => {
        useFileBrowser().setRenderTreeList(false);

        expect(useFileBrowser().renderTreeList).toBe(false);
        expect(queueRedisHllEvents).toHaveBeenCalledWith([
          TRACKING_CLICK_FILE_BROWSER_SETTING,
          TRACKING_FILE_BROWSER_LIST,
        ]);
      });
    });

    describe('getters', () => {
      beforeEach(() => {
        useFileBrowser().setTreeData(mockFiles);
      });

      describe('flatBlobsList', () => {
        it('returns an empty array if treeEntries is null', () => {
          useFileBrowser().treeEntries = null;
          expect(useFileBrowser().flatBlobsList).toEqual([]);
        });

        it('returns only the entries with type "blob"', () => {
          const blobs = useFileBrowser().flatBlobsList;

          expect(blobs).toHaveLength(mockFiles.length);
          expect(blobs.every((f) => f.type === 'blob')).toBe(true);
          expect(blobs).toEqual(mockFiles);
        });
      });

      describe('allBlobs', () => {
        it('returns an array of objects grouped by parentPath', () => {
          const { allBlobs } = useFileBrowser();

          expect(allBlobs).toHaveLength(3);

          const appAssetsGroup = allBlobs.find((g) => g.path === 'app/assets');
          const libGroup = allBlobs.find((g) => g.path === 'lib');
          const rootGroup = allBlobs.find((g) => g.path === '/');

          expect(appAssetsGroup).toEqual({
            path: 'app/assets',
            isHeader: true,
            tree: [mockFiles[0], mockFiles[1]],
          });

          expect(libGroup.tree).toEqual([mockFiles[2]]);
          expect(rootGroup.tree).toEqual([mockFiles[3]]);
        });

        it('returns an empty array if treeEntries is null', () => {
          useFileBrowser().treeEntries = null;
          expect(useFileBrowser().allBlobs).toEqual([]);
        });
      });
    });
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
