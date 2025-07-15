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
import { useMockIntersectionObserver } from 'helpers/mock_dom_observer';
import { disableBrokenContentVisibility } from '~/rapid_diffs/app/content_visibility_fix';
import { useApp } from '~/rapid_diffs/stores/app';

jest.mock('~/lib/graphql');
jest.mock('~/awards_handler');
jest.mock('~/mr_notes/stores');
jest.mock('~/rapid_diffs/app/view_settings');
jest.mock('~/rapid_diffs/app/init_hidden_files_warning');
jest.mock('~/rapid_diffs/app/init_file_browser');
jest.mock('~/rapid_diffs/app/safari_fix');
jest.mock('~/rapid_diffs/app/content_visibility_fix');

describe('Rapid Diffs App', () => {
  const { trigger } = useMockIntersectionObserver();

  let app;

  const appData = {
    diffsStreamUrl: '/stream',
    reloadStreamUrl: '/reload',
    diffsStatsEndpoint: '/stats',
    diffFilesEndpoint: '/diff-files-metadata',
    shouldSortMetadataFiles: true,
    lazy: false,
  };
  const getHiddenFilesWarningTarget = () => document.querySelector('[data-hidden-files-warning]');
  const getDiffFile = () => document.querySelector('diff-file');

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
    expect(disableBrokenContentVisibility).toHaveBeenCalled();
    expect(initFileBrowser).toHaveBeenCalledWith({
      toggleTarget: document.querySelector('[data-file-browser-toggle]'),
      browserTarget: document.querySelector('[data-file-browser]'),
      appData: app.appData,
    });
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
    expect(useDiffsList().streamRemainingDiffs).toHaveBeenCalledWith(
      '/stream',
      document.querySelector('[data-stream-remaining-diffs]'),
      preload,
    );
  });

  it('inits lazy app', () => {
    // eslint-disable-next-line vue/one-component-per-file
    createApp({ lazy: true });
    app.init();
    expect(useDiffsList().reloadDiffs).toHaveBeenCalledWith('/reload', true);
  });

  it('reacts to files loading', () => {
    createApp();
    app.init();
    document.querySelector('[data-rapid-diffs]').dispatchEvent(new CustomEvent(DIFF_FILE_MOUNTED));
    expect(useDiffsList(pinia).addLoadedFile).toHaveBeenCalled();
  });

  it('skips sorting', () => {
    // eslint-disable-next-line vue/one-component-per-file
    createApp({ shouldSortMetadataFiles: false });
    app.init();
    expect(app.appData.shouldSortMetadataFiles).toBe(false);
  });

  it('hides the app', () => {
    createApp();
    app.hide();
    expect(useApp().appVisible).toBe(false);
  });

  it('shows the app', () => {
    createApp();
    app.hide();
    app.show();
    expect(useApp().appVisible).toBe(true);
  });

  it('delegates clicks', () => {
    const onClick = jest.fn();
    createApp();
    getDiffFile().onClick = onClick;
    app.init();
    document.querySelector('button').click();
    expect(onClick).toHaveBeenCalled();
  });

  it('delegates visibility', () => {
    const onVisible = jest.fn();
    const onInvisible = jest.fn();
    createApp();
    getDiffFile().onVisible = onVisible;
    getDiffFile().onInvisible = onInvisible;
    app.init();
    app.observe(getDiffFile());
    trigger(getDiffFile(), { entry: { isIntersecting: true, target: getDiffFile() } });
    expect(onVisible).toHaveBeenCalled();
    trigger(getDiffFile(), { entry: { isIntersecting: false, target: getDiffFile() } });
    expect(onInvisible).toHaveBeenCalled();
  });
});
