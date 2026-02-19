import { createTestingPinia } from '@pinia/testing';
import { createMergeRequestRapidDiffsApp } from '~/rapid_diffs/merge_request_app';
import { setHTMLFixture } from 'helpers/fixtures';
import { useDiffsView } from '~/rapid_diffs/stores/diffs_view';
import { initFileBrowser } from '~/rapid_diffs/app/file_browser';
import { useDiffsList } from '~/rapid_diffs/stores/diffs_list';

jest.mock('~/lib/graphql');
jest.mock('~/rapid_diffs/app/view_settings');
jest.mock('~/rapid_diffs/app/init_hidden_files_warning');
jest.mock('~/rapid_diffs/app/file_browser');
jest.mock('~/rapid_diffs/app/quirks/safari_fix');
jest.mock('~/rapid_diffs/app/quirks/content_visibility_fix');

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

  const createApp = (data = {}) => {
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
    createTestingPinia({ stubActions: false });
    useDiffsView().loadDiffsStats.mockResolvedValue();
    useDiffsList().reloadDiffs.mockResolvedValue();
    useDiffsList().streamRemainingDiffs.mockResolvedValue();
    initFileBrowser.mockResolvedValue();
  });

  it('initializes app', async () => {
    createApp();
    await app.init();
    expect(app.root).toBeDefined();
  });

  it('initializes file browser', async () => {
    createApp();
    await app.init();
    expect(initFileBrowser).toHaveBeenCalled();
  });
});
