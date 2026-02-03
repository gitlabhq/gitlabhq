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
import { INLINE_DIFF_VIEW_TYPE, PARALLEL_DIFF_VIEW_TYPE } from '~/diffs/constants';
import { useDiffsList } from '~/rapid_diffs/stores/diffs_list';
import { initTimeline } from '~/rapid_diffs/app/init_timeline';
import TaskList from '~/task_list';

jest.mock('~/alert');
jest.mock('~/lib/graphql');
jest.mock('~/rapid_diffs/app/view_settings');
jest.mock('~/rapid_diffs/app/init_hidden_files_warning');
jest.mock('~/rapid_diffs/app/file_browser');
jest.mock('~/rapid_diffs/app/quirks/safari_fix');
jest.mock('~/rapid_diffs/app/quirks/content_visibility_fix');
jest.mock('~/rapid_diffs/app/init_new_discussions_toggle');
jest.mock('~/rapid_diffs/app/init_timeline');
jest.mock('~/task_list');

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

  const createApp = (data = {}, options = {}) => {
    setHTMLFixture(
      `
      <main>
        <div class="container-fluid ${options.fixedLayout ? 'js-fixed-layout container-limited' : ''}" data-diffs-container>
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
            <div data-commit-timeline></div>
          </div>
       </div>
      </main>
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
    createTestingPinia({ stubActions: false });
    useDiffsView().loadDiffsStats.mockResolvedValue();
    useDiffsList().reloadDiffs.mockResolvedValue();
    useDiffsList().streamRemainingDiffs.mockResolvedValue();
    initFileBrowser.mockResolvedValue();
  });

  it('initializes discussions', async () => {
    const discussions = [{ notes: [] }];
    axiosMock.onGet(appData.discussionsEndpoint).reply(HTTP_STATUS_OK, { discussions });
    createApp();
    await app.init();
    expect(useDiffDiscussions().setInitialDiscussions).toHaveBeenCalledWith(discussions);
    expect(initNewDiscussionToggle).toHaveBeenCalledWith(app.root);
  });

  it('shows alert when failed to init discussions', async () => {
    axiosMock.onGet(appData.discussionsEndpoint).reply(HTTP_STATUS_INTERNAL_SERVER_ERROR);
    createApp();
    await app.init();
    expect(useDiffDiscussions().setInitialDiscussions).not.toHaveBeenCalled();
    expect(createAlert).toHaveBeenCalledWith({
      message: 'Failed to load discussions. Try to reload the page.',
      error: expect.any(Error),
    });
  });

  describe('container layout switching', () => {
    beforeEach(() => {
      const discussions = [{}];
      axiosMock.onGet(appData.discussionsEndpoint).reply(HTTP_STATUS_OK, { discussions });
    });

    it('switches container layout when switching view types with fixed layout', async () => {
      // eslint-disable-next-line vue/one-component-per-file
      createApp({}, { fixedLayout: true });
      await app.init();
      const diffsContainer = document.querySelector('[data-diffs-container]');
      expect(diffsContainer.classList.contains('container-limited')).toBe(true);
      useDiffsView().updateViewType(PARALLEL_DIFF_VIEW_TYPE);
      expect(diffsContainer.classList.contains('container-limited')).toBe(false);
      useDiffsView().updateViewType(INLINE_DIFF_VIEW_TYPE);
      expect(diffsContainer.classList.contains('container-limited')).toBe(true);
    });

    it('does not switch container layout when js-fixed-layout is not present', async () => {
      // eslint-disable-next-line vue/one-component-per-file
      createApp({}, { fixedLayout: false });
      await app.init();
      const diffsContainer = document.querySelector('[data-diffs-container]');
      expect(diffsContainer.classList.contains('container-limited')).toBe(false);
      useDiffsView().updateViewType(PARALLEL_DIFF_VIEW_TYPE);
      expect(diffsContainer.classList.contains('container-limited')).toBe(false);
      useDiffsView().updateViewType(INLINE_DIFF_VIEW_TYPE);
      expect(diffsContainer.classList.contains('container-limited')).toBe(false);
    });
  });

  it('initializes timeline', async () => {
    axiosMock.onGet(appData.discussionsEndpoint).reply(HTTP_STATUS_OK, { discussions: [] });
    createApp();
    await app.init();
    expect(initTimeline).toHaveBeenCalledWith(
      expect.objectContaining({
        discussionsEndpoint: appData.discussionsEndpoint,
      }),
    );
  });

  describe('TaskList integration', () => {
    it('initializes TaskList with correct configuration', async () => {
      axiosMock.onGet(appData.discussionsEndpoint).reply(HTTP_STATUS_OK, { discussions: [] });
      createApp();
      await app.init();

      expect(TaskList).toHaveBeenCalledWith({
        dataType: 'note',
        fieldName: 'note',
        selector: '[data-rapid-diffs]',
        onSuccess: expect.any(Function),
        onError: expect.any(Function),
      });
    });

    it('updates note text on TaskList success', async () => {
      const noteId = 'note-123';
      const discussions = [
        {
          id: 'discussion-1',
          notes: [{ id: noteId, note: 'Original note text' }],
        },
      ];
      axiosMock.onGet(appData.discussionsEndpoint).reply(HTTP_STATUS_OK, { discussions });
      createApp();
      await app.init();

      const taskListConfig = TaskList.mock.calls[0][0];
      const updatedNote = 'Updated note text';

      taskListConfig.onSuccess({ id: noteId, note: updatedNote });

      expect(useDiffDiscussions().updateNoteTextById).toHaveBeenCalledWith(noteId, updatedNote);
    });

    it('shows alert on TaskList error', async () => {
      axiosMock.onGet(appData.discussionsEndpoint).reply(HTTP_STATUS_OK, { discussions: [] });
      createApp();
      await app.init();

      const taskListConfig = TaskList.mock.calls[0][0];
      const error = new Error('TaskList failed');

      taskListConfig.onError(error);

      expect(createAlert).toHaveBeenCalledWith({
        message: 'Something went wrong while editing your comment. Please try again.',
        error,
      });
    });
  });
});
