import { setActivePinia } from 'pinia';
import { createTestingPinia } from '@pinia/testing';
import MockAdapter from 'axios-mock-adapter';
import waitForPromises from 'helpers/wait_for_promises';
import { useDiffsView } from '~/rapid_diffs/stores/diffs_view';
import { useDiffsList } from '~/rapid_diffs/stores/diffs_list';
import { useFileBrowser } from '~/diffs/stores/file_browser';
import { setCookie } from '~/lib/utils/common_utils';
import {
  DIFF_VIEW_COOKIE_NAME,
  TRACKING_CLICK_DIFF_VIEW_SETTING,
  TRACKING_CLICK_SINGLE_FILE_SETTING,
  TRACKING_DIFF_VIEW_INLINE,
  TRACKING_DIFF_VIEW_PARALLEL,
  TRACKING_MULTIPLE_FILES_MODE,
  TRACKING_SINGLE_FILE_MODE,
} from '~/diffs/constants';
import { queueRedisHllEvents } from '~/diffs/utils/queue_events';
import axios from '~/lib/utils/axios_utils';
import { HTTP_STATUS_OK } from '~/lib/utils/http_status';

const defaultState = {
  updateUserEndpoint: '/update',
  streamUrl: '/stream',
};

jest.mock('~/lib/utils/common_utils');
jest.mock('~/diffs/utils/queue_events');

describe('Diffs view store', () => {
  let store;
  let mockAxios;

  beforeEach(() => {
    mockAxios = new MockAdapter(axios);
    mockAxios.onPut(defaultState.updateUserEndpoint).reply(HTTP_STATUS_OK);
    const pinia = createTestingPinia({
      stubActions: false,
      initialState: {
        diffsView: defaultState,
      },
    });
    setActivePinia(pinia);
    store = useDiffsView();
    useDiffsList().reloadDiffs.mockResolvedValue();
  });

  it('has fileByFileMode default state', () => {
    expect(store.fileByFileMode).toBe(false);
    expect(store.singleFileMode).toBe(false);
  });

  describe('#loadDiffsStats', () => {
    const endpoint = '/stats';

    beforeEach(() => {
      store.diffsStatsEndpoint = endpoint;
    });

    it('loads diff stats', async () => {
      const addedLines = 10;
      const removedLines = 20;
      const diffsCount = 5;
      const realSize = '5';
      mockAxios.onGet(endpoint).reply(HTTP_STATUS_OK, {
        diffs_stats: {
          added_lines: addedLines,
          removed_lines: removedLines,
          diffs_count: diffsCount,
          real_size: realSize,
        },
      });
      await store.loadDiffsStats();
      expect(store.diffsStats).toEqual({ addedLines, removedLines, diffsCount, realSize });
      expect(store.overflow).toBe(null);
    });

    it('sets overflow', async () => {
      const addedLines = 10;
      const removedLines = 20;
      const diffsCount = 500;
      const visibleCount = 50;
      const emailPath = '/email';
      const diffPath = '/diff';
      mockAxios.onGet(endpoint).reply(HTTP_STATUS_OK, {
        diffs_stats: {
          added_lines: addedLines,
          removed_lines: removedLines,
          diffs_count: diffsCount,
        },
        overflow: {
          visible_count: visibleCount,
          email_path: emailPath,
          diff_path: diffPath,
        },
      });
      await store.loadDiffsStats();
      expect(store.overflow).toEqual({ visibleCount, emailPath, diffPath });
    });
  });

  describe('#updateDiffView', () => {
    it('calls reloadDiffs on diffsList store', () => {
      const spy = useDiffsList().reloadDiffs.mockResolvedValue();
      store.updateDiffView();
      expect(spy).toHaveBeenCalledWith(`${defaultState.streamUrl}?view=inline&w=0`);
    });
  });

  describe('#updateViewType', () => {
    it('handles switch to parallel view', () => {
      store.updateViewType('parallel');
      expect(useDiffsList().reloadDiffs).toHaveBeenCalledWith(
        `${defaultState.streamUrl}?view=parallel&w=0`,
      );
      expect(setCookie).toHaveBeenCalledWith(DIFF_VIEW_COOKIE_NAME, 'parallel');
      expect(queueRedisHllEvents).toHaveBeenCalledWith([
        TRACKING_CLICK_DIFF_VIEW_SETTING,
        TRACKING_DIFF_VIEW_PARALLEL,
      ]);
      expect(store.viewType).toEqual('parallel');
    });

    it('handles switch to inline view', () => {
      store.updateViewType('inline');
      expect(useDiffsList().reloadDiffs).toHaveBeenCalledWith(
        `${defaultState.streamUrl}?view=inline&w=0`,
      );
      expect(setCookie).toHaveBeenCalledWith(DIFF_VIEW_COOKIE_NAME, 'inline');
      expect(queueRedisHllEvents).toHaveBeenCalledWith([
        TRACKING_CLICK_DIFF_VIEW_SETTING,
        TRACKING_DIFF_VIEW_INLINE,
      ]);
      expect(store.viewType).toEqual('inline');
    });
  });

  describe('#toggleFileByFile', () => {
    it('enables file by file mode', () => {
      store.toggleFileByFile(true);
      expect(store.fileByFileMode).toBe(true);
      expect(store.singleFileMode).toBe(true);
      expect(queueRedisHllEvents).toHaveBeenCalledWith([
        TRACKING_CLICK_SINGLE_FILE_SETTING,
        TRACKING_SINGLE_FILE_MODE,
      ]);
    });

    it('disables file by file mode', () => {
      store.fileByFileMode = true;
      store.singleFileMode = true;
      store.toggleFileByFile(false);
      expect(store.fileByFileMode).toBe(false);
      expect(store.singleFileMode).toBe(false);
      expect(queueRedisHllEvents).toHaveBeenCalledWith([
        TRACKING_CLICK_SINGLE_FILE_SETTING,
        TRACKING_MULTIPLE_FILES_MODE,
      ]);
    });

    it('persists preference for authenticated users', async () => {
      store.toggleFileByFile(true);
      await waitForPromises();
      expect(
        mockAxios.history.put.some(
          (item) => JSON.parse(item.data).view_diffs_file_by_file === true,
        ),
      ).toBe(true);
    });

    it('does not persist when updateUserEndpoint is undefined', async () => {
      store.updateUserEndpoint = undefined;
      store.toggleFileByFile(true);
      await waitForPromises();
      expect(mockAxios.history.put).toHaveLength(0);
    });

    it('calls loadCurrentFile when enabling', () => {
      useDiffsList().loadSingleFile.mockResolvedValue();
      store.diffFileEndpoint = '/diff_file';
      useFileBrowser().tree = [
        { type: 'blob', filePaths: { old: 'a.js', new: 'a.js' }, fileHash: 'abc' },
      ];
      store.toggleFileByFile(true);
      expect(useDiffsList().loadSingleFile).toHaveBeenCalled();
    });

    it('calls reloadDiffs when disabling', () => {
      store.singleFileMode = true;
      store.toggleFileByFile(false);
      expect(useDiffsList().reloadDiffs).toHaveBeenCalledWith(
        `${defaultState.streamUrl}?view=inline&w=0`,
      );
    });
  });

  describe('#updateShowWhitespace', () => {
    it('handles switch to hide whitespace', () => {
      store.updateShowWhitespace(false);
      expect(useDiffsList().reloadDiffs).toHaveBeenCalledWith(
        `${defaultState.streamUrl}?view=inline&w=1`,
      );
      expect(store.showWhitespace).toEqual(false);
    });

    it('handles switch to show whitespace', () => {
      store.updateShowWhitespace(true);
      expect(useDiffsList().reloadDiffs).toHaveBeenCalledWith(
        `${defaultState.streamUrl}?view=inline&w=0`,
      );
      expect(store.showWhitespace).toEqual(true);
    });

    it('stores setting for authenticated users', async () => {
      store.updateShowWhitespace(true);
      await waitForPromises();
      expect(
        mockAxios.history.put.some(
          (item) => JSON.parse(item.data).show_whitespace_in_diffs === true,
        ),
      ).toBe(true);
    });
  });

  describe('#totalFilesCount', () => {
    it('returns diffs count when real size is not provided', () => {
      store.diffsStats = { diffsCount: 10 };
      expect(store.totalFilesCount).toBe(10);
    });

    it('returns real size when provided so the "+" suffix is preserved', () => {
      store.diffsStats = { diffsCount: 10, realSize: '10+' };
      expect(store.totalFilesCount).toBe('10+');
    });
  });

  describe('file-by-file navigation', () => {
    const files = [
      { type: 'blob', filePaths: { old: 'a.js', new: 'a.js' }, fileHash: 'aaa' },
      { type: 'blob', filePaths: { old: 'b.js', new: 'b.js' }, fileHash: 'bbb' },
      { type: 'blob', filePaths: { old: 'c.js', new: 'c.js' }, fileHash: 'ccc' },
    ];

    beforeEach(() => {
      store.diffFileEndpoint = '/diff_file';
      store.singleFileMode = true;
      useFileBrowser().tree = files;
      useDiffsList().loadSingleFile.mockResolvedValue();
    });

    describe('#loadCurrentFile', () => {
      it('loads the file at currentFileIndex', () => {
        store.currentFileIndex = 1;
        store.loadCurrentFile();
        expect(useDiffsList().loadSingleFile).toHaveBeenCalledWith({
          endpoint: '/diff_file',
          oldPath: 'b.js',
          newPath: 'b.js',
          viewType: 'inline',
          showWhitespace: true,
        });
      });

      it('does nothing when index is out of bounds', () => {
        store.currentFileIndex = 5;
        store.loadCurrentFile();
        expect(useDiffsList().loadSingleFile).not.toHaveBeenCalled();
      });
    });

    describe('#goToFile', () => {
      it('updates currentFileIndex and loads the file', () => {
        store.goToFile(2);
        expect(store.currentFileIndex).toBe(2);
        expect(useDiffsList().loadSingleFile).toHaveBeenCalledWith({
          endpoint: '/diff_file',
          oldPath: 'c.js',
          newPath: 'c.js',
          viewType: 'inline',
          showWhitespace: true,
        });
      });

      it('does nothing for negative index', () => {
        store.goToFile(-1);
        expect(store.currentFileIndex).toBe(0);
        expect(useDiffsList().loadSingleFile).not.toHaveBeenCalled();
      });

      it('does nothing for index beyond file count', () => {
        store.goToFile(3);
        expect(store.currentFileIndex).toBe(0);
        expect(useDiffsList().loadSingleFile).not.toHaveBeenCalled();
      });
    });

    describe('#goToNextFile', () => {
      it('advances to the next file', () => {
        store.currentFileIndex = 0;
        store.goToNextFile();
        expect(store.currentFileIndex).toBe(1);
      });

      it('does nothing at the last file', () => {
        store.currentFileIndex = 2;
        store.goToNextFile();
        expect(store.currentFileIndex).toBe(2);
      });
    });

    describe('#goToPrevFile', () => {
      it('goes to the previous file', () => {
        store.currentFileIndex = 2;
        store.goToPrevFile();
        expect(store.currentFileIndex).toBe(1);
      });

      it('does nothing at the first file', () => {
        store.currentFileIndex = 0;
        store.goToPrevFile();
        expect(store.currentFileIndex).toBe(0);
      });
    });

    describe('navigation getters', () => {
      it('currentFileNumber is 1-indexed', () => {
        store.currentFileIndex = 0;
        expect(store.currentFileNumber).toBe(1);
      });

      it('hasNextFile is true when not at the end', () => {
        store.currentFileIndex = 1;
        expect(store.hasNextFile).toBe(true);
      });

      it('hasNextFile is false at the last file', () => {
        store.currentFileIndex = 2;
        expect(store.hasNextFile).toBe(false);
      });

      it('hasPrevFile is true when not at the start', () => {
        store.currentFileIndex = 1;
        expect(store.hasPrevFile).toBe(true);
      });

      it('hasPrevFile is false at the first file', () => {
        store.currentFileIndex = 0;
        expect(store.hasPrevFile).toBe(false);
      });
    });
  });

  describe('#updateDiffView in single file mode', () => {
    it('loads current file instead of reloading all diffs', () => {
      store.singleFileMode = true;
      store.diffFileEndpoint = '/diff_file';
      useFileBrowser().tree = [
        { type: 'blob', filePaths: { old: 'a.js', new: 'a.js' }, fileHash: 'aaa' },
      ];
      useDiffsList().loadSingleFile.mockResolvedValue();
      store.updateDiffView();
      expect(useDiffsList().loadSingleFile).toHaveBeenCalled();
      expect(useDiffsList().reloadDiffs).not.toHaveBeenCalled();
    });
  });
});
