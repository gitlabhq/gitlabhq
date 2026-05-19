import { createTestingPinia } from '@pinia/testing';
import { createMergeRequestRapidDiffsApp } from '~/rapid_diffs/merge_request_app';
import { setHTMLFixture } from 'helpers/fixtures';
import { useDiffsView } from '~/rapid_diffs/stores/diffs_view';
import { initFileBrowser } from '~/rapid_diffs/app/file_browser';
import { useDiffsList } from '~/rapid_diffs/stores/diffs_list';
import { useCodeReview } from '~/diffs/stores/code_review';
import { useLegacyDiffs } from '~/diffs/stores/legacy_diffs';
import { useMergeRequestDiscussions } from '~/merge_request/stores/merge_request_discussions';
import { DiffFile } from '~/rapid_diffs/web_components/diff_file';
import { initCompareVersions } from '~/rapid_diffs/app/init_compare_versions';
import { initNewDiscussionToggle } from '~/rapid_diffs/app/init_new_discussions_toggle';
import { initLineRangeSelection } from '~/rapid_diffs/app/init_line_range_selection';
import { globalAccessorPlugin } from '~/pinia/plugins';

jest.mock('~/lib/graphql');
jest.mock('~/rapid_diffs/app/view_settings');
jest.mock('~/rapid_diffs/app/init_hidden_files_warning');
jest.mock('~/rapid_diffs/app/file_browser');
jest.mock('~/rapid_diffs/app/quirks/safari_fix');
jest.mock('~/rapid_diffs/app/quirks/content_visibility_fix');
jest.mock('~/rapid_diffs/app/init_compare_versions');
jest.mock('~/rapid_diffs/app/init_new_discussions_toggle');
jest.mock('~/rapid_diffs/app/init_line_range_selection');

describe('Merge Request Rapid Diffs app', () => {
  let app;

  const appData = {
    diffsStreamUrl: '/stream',
    reloadStreamUrl: '/reload',
    diffsStatsEndpoint: '/stats',
    diffFilesEndpoint: '/diff-files-metadata',
    shouldSortMetadataFiles: true,
    lazy: false,
  };

  const buildApp = (data = {}) => {
    setHTMLFixture(
      `
      <main>
        <div class="container-fluid" data-diffs-container>
        <div
            data-rapid-diffs
            data-app-data='${JSON.stringify({ ...appData, ...data })}'
          >
            <diff-file>
              <button>Click me!</button>
            </diff-file>
            <div data-view-settings></div>
            <div data-list-loading></div>
            <div data-file-browser></div>
            <div data-file-browser-toggle></div>
            <div data-hidden-files-warning></div>
            <div data-stream-remaining-diffs></div>
            <div data-after-browser-toggle></div>
          </div>
       </div>
      </main>
      `,
    );
    app = createMergeRequestRapidDiffsApp();
  };

  beforeAll(() => {
    Object.defineProperty(window, 'customElements', {
      value: { define: jest.fn() },
      writable: true,
    });
  });

  beforeEach(() => {
    window.gon = { current_user_id: 1 };
    createTestingPinia({ plugins: [globalAccessorPlugin] });
    useLegacyDiffs();
    useDiffsView().loadDiffsStats.mockResolvedValue();
    useDiffsList().reloadDiffs.mockResolvedValue();
    useDiffsList().streamRemainingDiffs.mockResolvedValue();
    useMergeRequestDiscussions().fetchNotesAndDrafts.mockResolvedValue();
    initFileBrowser.mockResolvedValue();
  });

  afterEach(() => {
    window.gon = {};
  });

  it('initializes app', async () => {
    buildApp();
    await app.init();
    expect(app.root).toBeDefined();
  });

  it('initializes file browser', async () => {
    buildApp();
    await app.init();
    expect(initFileBrowser).toHaveBeenCalled();
  });

  it('initializes code review store with mrPath', async () => {
    buildApp({ mr_path: '/namespace/project/-/merge_requests/1' });
    await app.init();
    expect(useCodeReview().setMrPath).toHaveBeenCalledWith('/namespace/project/-/merge_requests/1');
    expect(useCodeReview().restoreFromAutosave).toHaveBeenCalled();
    expect(useCodeReview().restoreFromLegacyMrReviews).toHaveBeenCalled();
  });

  it('skips code review initialization when mrPath is not provided', async () => {
    buildApp();
    await app.init();
    expect(useCodeReview().setMrPath).not.toHaveBeenCalled();
  });

  it('skips code review initialization when user is not authenticated', async () => {
    window.gon = {};
    buildApp({ mr_path: '/namespace/project/-/merge_requests/1' });
    await app.init();
    expect(useCodeReview().setMrPath).not.toHaveBeenCalled();
  });

  it('fetches notes and drafts on init', async () => {
    buildApp();
    await app.init();
    expect(useMergeRequestDiscussions().fetchNotesAndDrafts).toHaveBeenCalled();
  });

  it('initializes compare versions on init', async () => {
    const versions = {
      source_versions: [{ id: 1, version_index: 1, selected: true }],
      target_versions: [{ id: 'head', head: true, selected: true }],
    };
    buildApp({ versions });
    await app.init();

    expect(initCompareVersions).toHaveBeenCalledWith(
      document.querySelector('[data-after-browser-toggle]'),
      expect.objectContaining({ versions }),
    );
  });

  it('skips compare versions when versions data is absent', async () => {
    buildApp();
    await app.init();

    expect(initCompareVersions).not.toHaveBeenCalled();
  });

  it('initializes new discussion toggle with allowExpandedLines', async () => {
    buildApp();
    await app.init();
    expect(initNewDiscussionToggle).toHaveBeenCalledWith(app.root, { allowExpandedLines: true });
  });

  it('initializes line range selection', async () => {
    buildApp();
    await app.init();
    expect(initLineRangeSelection).toHaveBeenCalledWith(app.root);
  });

  describe('scrollToDiffNote', () => {
    const discussion = {
      hidden: true,
      original_position: {
        old_path: 'file.js',
        new_path: 'file.js',
        old_line: 5,
        new_line: 10,
      },
    };

    const mockDiffFile = {
      data: { oldPath: 'file.js', newPath: 'file.js' },
      selectLine: jest.fn(),
    };

    beforeEach(() => {
      buildApp();
      jest.spyOn(DiffFile, 'getAll').mockReturnValue([mockDiffFile]);
      mockDiffFile.selectLine.mockClear();
    });

    it('selects the line on the matching diff file', () => {
      app.scrollToDiffNote(discussion);
      expect(mockDiffFile.selectLine).toHaveBeenCalledWith(5, 10);
    });

    it('uses line_range end when present', () => {
      const disc = {
        ...discussion,
        original_position: {
          ...discussion.original_position,
          line_range: { end: { old_line: 8, new_line: 15 } },
        },
      };
      app.scrollToDiffNote(disc);
      expect(mockDiffFile.selectLine).toHaveBeenCalledWith(8, 15);
    });

    it('expands the discussion', () => {
      app.scrollToDiffNote(discussion);
      expect(useMergeRequestDiscussions().expandDiscussion).toHaveBeenCalledWith(discussion);
    });

    it('does not select line when file is not found', () => {
      jest.spyOn(DiffFile, 'getAll').mockReturnValue([]);
      app.scrollToDiffNote(discussion);
      expect(mockDiffFile.selectLine).not.toHaveBeenCalled();
    });
  });

  describe('setLinkedFile', () => {
    it('sets linked file data on the diffs list store', () => {
      buildApp();
      app.setLinkedFile({ old_path: 'a.js', new_path: 'b.js' });
      expect(useDiffsList().setLinkedFileData).toHaveBeenCalledWith({
        old_path: 'a.js',
        new_path: 'b.js',
      });
    });
  });
});
