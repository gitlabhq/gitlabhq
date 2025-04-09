import { createTestingPinia } from '@pinia/testing';
import { setHTMLFixture } from 'helpers/fixtures';
import { createRapidDiffsApp } from '~/rapid_diffs/app';
import { initViewSettings } from '~/rapid_diffs/app/view_settings';
import { DiffFile } from '~/rapid_diffs/diff_file';
import { DiffFileMounted } from '~/rapid_diffs/diff_file_mounted';
import { useDiffsList } from '~/rapid_diffs/stores/diffs_list';
import { pinia } from '~/pinia/instance';
import { initHiddenFilesWarning } from '~/rapid_diffs/app/init_hidden_files_warning';
import { initFileBrowser } from '~/rapid_diffs/app/init_file_browser';
import { StreamingError } from '~/rapid_diffs/streaming_error';
import { useDiffsView } from '~/rapid_diffs/stores/diffs_view';
import { fixWebComponentsStreamingOnSafari } from '~/rapid_diffs/app/safari_fix';
import { DIFF_FILE_MOUNTED } from '~/rapid_diffs/dom_events';

jest.mock('~/lib/graphql');
jest.mock('~/awards_handler');
jest.mock('~/mr_notes/stores');
jest.mock('~/rapid_diffs/app/view_settings');
jest.mock('~/rapid_diffs/app/init_hidden_files_warning');
jest.mock('~/rapid_diffs/app/init_file_browser');
jest.mock('~/rapid_diffs/app/safari_fix');

describe('Rapid Diffs App', () => {
  let app;

  const createApp = (options) => {
    app = createRapidDiffsApp(options);
  };

  beforeEach(() => {
    createTestingPinia();
    useDiffsView(pinia).loadMetadata.mockResolvedValue();
    initFileBrowser.mockResolvedValue();
    setHTMLFixture(
      `
        <div data-rapid-diffs data-reload-stream-url="/reload" data-metadata-endpoint="/metadata" data-diff-files-endpoint="/diff-files-metadata">
          <div id="js-stream-container" data-diffs-stream-url="/stream"></div>
        </div>
      `,
    );
  });

  beforeAll(() => {
    Object.defineProperty(window, 'customElements', {
      value: { define: jest.fn() },
      writable: true,
    });
  });

  it('initializes the app', async () => {
    let res;
    const mock = useDiffsView().loadMetadata.mockImplementationOnce(
      () =>
        new Promise((resolve) => {
          res = resolve;
        }),
    );
    createApp();
    app.init();
    expect(useDiffsView().metadataEndpoint).toBe('/metadata');
    expect(mock).toHaveBeenCalled();
    expect(initViewSettings).toHaveBeenCalledWith({ pinia, streamUrl: '/reload' });
    expect(window.customElements.define).toHaveBeenCalledWith('diff-file', DiffFile);
    expect(window.customElements.define).toHaveBeenCalledWith('diff-file-mounted', DiffFileMounted);
    expect(window.customElements.define).toHaveBeenCalledWith('streaming-error', StreamingError);
    await res();
    expect(initHiddenFilesWarning).toHaveBeenCalled();
    expect(fixWebComponentsStreamingOnSafari).toHaveBeenCalled();
    expect(initFileBrowser).toHaveBeenCalledWith('/diff-files-metadata');
  });

  it('streams remaining diffs', () => {
    createApp();
    app.init();
    app.streamRemainingDiffs();
    expect(useDiffsList().streamRemainingDiffs).toHaveBeenCalledWith('/stream');
  });

  it('reloads diff files', () => {
    createApp();
    app.init();
    app.reloadDiffs();
    expect(useDiffsList().reloadDiffs).toHaveBeenCalledWith('/reload');
  });

  it('reacts to files loading', () => {
    createApp();
    app.init();
    document.dispatchEvent(new CustomEvent(DIFF_FILE_MOUNTED));
    expect(useDiffsList(pinia).addLoadedFile).toHaveBeenCalled();
  });
});
