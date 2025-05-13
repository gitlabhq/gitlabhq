import { createTestingPinia } from '@pinia/testing';
import { setHTMLFixture } from 'helpers/fixtures';
import { createRapidDiffsApp } from '~/rapid_diffs/app';
import { initViewSettings } from '~/rapid_diffs/app/view_settings';
import { DiffFile } from '~/rapid_diffs/diff_file';
import { useDiffsList } from '~/rapid_diffs/stores/diffs_list';
import { pinia } from '~/pinia/instance';
import { initHiddenFilesWarning } from '~/rapid_diffs/app/init_hidden_files_warning';
import { initFileBrowser } from '~/rapid_diffs/app/init_file_browser';
import { StreamingError } from '~/rapid_diffs/streaming_error';
import { useDiffsView } from '~/rapid_diffs/stores/diffs_view';
import { fixWebComponentsStreamingOnSafari } from '~/rapid_diffs/app/safari_fix';
import { DIFF_FILE_MOUNTED } from '~/rapid_diffs/dom_events';
import { disableContentVisibilityOnOlderChrome } from '~/rapid_diffs/app/chrome_fix';

jest.mock('~/lib/graphql');
jest.mock('~/awards_handler');
jest.mock('~/mr_notes/stores');
jest.mock('~/rapid_diffs/app/view_settings');
jest.mock('~/rapid_diffs/app/init_hidden_files_warning');
jest.mock('~/rapid_diffs/app/init_file_browser');
jest.mock('~/rapid_diffs/app/safari_fix');
jest.mock('~/rapid_diffs/app/chrome_fix');

describe('Rapid Diffs App', () => {
  let app;

  const appData = {
    diffsStreamUrl: '/stream',
    reloadStreamUrl: '/reload',
    diffsStatsEndpoint: '/stats',
    diffFilesEndpoint: '/diff-files-metadata',
    shouldSortMetadataFiles: true,
  };
  const getHiddenFilesWarningTarget = () => document.querySelector('[data-hidden-files-warning]');

  const createApp = (data = {}) => {
    setHTMLFixture(
      `
        <div
          data-rapid-diffs
          data-app-data='${JSON.stringify({ ...appData, ...data })}'
        >
          <div data-view-settings></div>
          <div data-file-browser></div>
          <div data-file-browser-toggle></div>
          <div data-hidden-files-warning></div>
          <div data-stream-remaining-diffs></div>
        </div>
      `,
    );
    app = createRapidDiffsApp();
  };

  beforeAll(() => {
    Object.defineProperty(window, 'customElements', {
      value: { define: jest.fn() },
      writable: true,
    });
  });

  beforeEach(() => {
    createTestingPinia();
    useDiffsView().loadDiffsStats.mockResolvedValue();
    initFileBrowser.mockResolvedValue();
  });

  it('initializes the app', () => {
    createApp();
    app.init();
    expect(useDiffsView().diffsStatsEndpoint).toBe('/stats');
    expect(useDiffsView().loadDiffsStats).toHaveBeenCalled();
    expect(initViewSettings).toHaveBeenCalledWith({
      pinia,
      appData: app.appData,
      target: document.querySelector('[data-view-settings]'),
    });
    expect(window.customElements.define).toHaveBeenCalledWith('diff-file', DiffFile);
    expect(window.customElements.define).toHaveBeenCalledWith(
      'diff-file-mounted',
      expect.any(Function),
    );
    expect(window.customElements.define).toHaveBeenCalledWith('streaming-error', StreamingError);
    expect(initHiddenFilesWarning).toHaveBeenCalledWith(getHiddenFilesWarningTarget());
    expect(fixWebComponentsStreamingOnSafari).toHaveBeenCalled();
    expect(disableContentVisibilityOnOlderChrome).toHaveBeenCalled();
    expect(initFileBrowser).toHaveBeenCalledWith({
      toggleTarget: document.querySelector('[data-file-browser-toggle]'),
      browserTarget: document.querySelector('[data-file-browser]'),
      appData: app.appData,
    });
  });

  it('streams remaining diffs', () => {
    createApp();
    app.init();
    app.streamRemainingDiffs();
    expect(useDiffsList().streamRemainingDiffs).toHaveBeenCalledWith(
      '/stream',
      document.querySelector('[data-stream-remaining-diffs]'),
      undefined,
    );
  });

  it('streams preloaded remaining diffs', () => {
    const preload = {};
    window.gl.rapidDiffsPreload = preload;
    createApp();
    app.init();
    app.streamRemainingDiffs();
    expect(useDiffsList().streamRemainingDiffs).toHaveBeenCalledWith(
      '/stream',
      document.querySelector('[data-stream-remaining-diffs]'),
      preload,
    );
  });

  it('reloads diff files', () => {
    createApp();
    app.init();
    app.reloadDiffs();
    expect(useDiffsList().reloadDiffs).toHaveBeenCalledWith('/reload', undefined);
  });

  it('loads initial diff files', () => {
    createApp();
    app.init();
    app.reloadDiffs(true);
    expect(useDiffsList().reloadDiffs).toHaveBeenCalledWith('/reload', true);
  });

  it('reacts to files loading', () => {
    createApp();
    app.init();
    document.querySelector('[data-rapid-diffs]').dispatchEvent(new CustomEvent(DIFF_FILE_MOUNTED));
    expect(useDiffsList(pinia).addLoadedFile).toHaveBeenCalled();
  });

  it('skips sorting', () => {
    createApp({ shouldSortMetadataFiles: false });
    app.init();
    expect(app.appData.shouldSortMetadataFiles).toBe(false);
  });
});
