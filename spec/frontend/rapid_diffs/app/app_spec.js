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

jest.mock('~/mr_notes/stores');
jest.mock('~/rapid_diffs/app/view_settings');
jest.mock('~/rapid_diffs/app/init_hidden_files_warning');
jest.mock('~/rapid_diffs/app/init_file_browser');

describe('Rapid Diffs App', () => {
  let app;

  const createApp = (options) => {
    app = createRapidDiffsApp(options);
  };

  beforeEach(() => {
    createTestingPinia();
    setHTMLFixture(
      `
        <div data-rapid-diffs data-reload-stream-url="/reload" data-metadata-endpoint="/metadata">
          <div id="js-stream-container" data-diffs-stream-url="/stream"></div>
        </div>
      `,
    );
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
    expect(window.customElements.get('diff-file')).toBe(DiffFile);
    expect(window.customElements.get('diff-file-mounted')).toBe(DiffFileMounted);
    expect(window.customElements.get('streaming-error')).toBe(StreamingError);
    await res();
    expect(initHiddenFilesWarning).toHaveBeenCalled();
    expect(initFileBrowser).toHaveBeenCalled();
  });

  it('streams remaining diffs', () => {
    createApp();
    app.streamRemainingDiffs();
    expect(useDiffsList().streamRemainingDiffs).toHaveBeenCalledWith('/stream');
  });

  it('reloads diff files', () => {
    createApp();
    app.reloadDiffs();
    expect(useDiffsList().reloadDiffs).toHaveBeenCalledWith('/reload');
  });
});
