import AxiosMockAdapter from 'axios-mock-adapter';
import { createTestingPinia } from '@pinia/testing';
import axios from '~/lib/utils/axios_utils';
import { createCommitRapidDiffsApp } from '~/rapid_diffs/commit_app';
import { useDiffDiscussions } from '~/rapid_diffs/stores/diff_discussions';
import { HTTP_STATUS_INTERNAL_SERVER_ERROR, HTTP_STATUS_OK } from '~/lib/utils/http_status';
import { setHTMLFixture } from 'helpers/fixtures';
import { useDiffsView } from '~/rapid_diffs/stores/diffs_view';
import { initFileBrowser } from '~/rapid_diffs/app/file_browser';
import { createAlert } from '~/alert';
import { initNewDiscussionToggle } from '~/rapid_diffs/app/init_new_discussions_toggle';

jest.mock('~/alert');
jest.mock('~/lib/graphql');
jest.mock('~/rapid_diffs/app/view_settings');
jest.mock('~/rapid_diffs/app/init_hidden_files_warning');
jest.mock('~/rapid_diffs/app/file_browser');
jest.mock('~/rapid_diffs/app/quirks/safari_fix');
jest.mock('~/rapid_diffs/app/quirks/content_visibility_fix');
jest.mock('~/rapid_diffs/app/init_new_discussions_toggle');

describe('Commit Rapid Diffs app', () => {
  let axiosMock;
  let app;

  const appData = {
    diffsStreamUrl: '/stream',
    reloadStreamUrl: '/reload',
    diffsStatsEndpoint: '/stats',
    diffFilesEndpoint: '/diff-files-metadata',
    discussionsEndpoint: '/discussions',
    shouldSortMetadataFiles: true,
    lazy: false,
  };

  const createApp = (data = {}) => {
    setHTMLFixture(
      `
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
      `,
    );
    app = createCommitRapidDiffsApp();
  };

  beforeAll(() => {
    Object.defineProperty(window, 'customElements', {
      value: { define: jest.fn() },
      writable: true,
    });
  });

  beforeEach(() => {
    axiosMock = new AxiosMockAdapter(axios);
    createTestingPinia();
    useDiffsView().loadDiffsStats.mockResolvedValue();
    initFileBrowser.mockResolvedValue();
  });

  it('initializes discussions', async () => {
    const discussions = [{}];
    axiosMock.onGet(appData.discussionsEndpoint).reply(HTTP_STATUS_OK, { discussions });
    createApp();
    app.init();
    await app.initDiscussions();
    expect(useDiffDiscussions().setInitialDiscussions).toHaveBeenCalledWith(discussions);
    expect(initNewDiscussionToggle).toHaveBeenCalledWith(app.root);
  });

  it('shows alert when failed to init discussions', async () => {
    axiosMock.onGet(appData.discussionsEndpoint).reply(HTTP_STATUS_INTERNAL_SERVER_ERROR);
    createApp();
    app.init();
    await app.initDiscussions();
    expect(useDiffDiscussions().setInitialDiscussions).not.toHaveBeenCalled();
    expect(createAlert).toHaveBeenCalledWith({
      message: 'Failed to load discussions. Try to reload the page.',
      error: expect.any(Error),
    });
  });
});
