import { createTestingPinia } from '@pinia/testing';
import { setHTMLFixture } from 'helpers/fixtures';
import { createRapidDiffsApp } from '~/rapid_diffs/app';
import { initViewSettings } from '~/rapid_diffs/app/view_settings';
import { DiffFile } from '~/rapid_diffs/diff_file';
import { DiffFileMounted } from '~/rapid_diffs/diff_file_mounted';
import { useDiffsList } from '~/rapid_diffs/stores/diffs_list';
import { pinia } from '~/pinia/instance';
import { initFileBrowser } from '~/rapid_diffs/app/file_browser';

jest.mock('~/rapid_diffs/app/view_settings');
jest.mock('~/rapid_diffs/app/file_browser');

describe('Rapid Diffs App', () => {
  let app;

  const createApp = (options) => {
    app = createRapidDiffsApp(options);
  };

  beforeEach(() => {
    createTestingPinia();
    setHTMLFixture(
      `
        <div data-rapid-diffs data-reload-stream-url="/reload">
          <div id="js-stream-container" data-diffs-stream-url="/stream"></div>
        </div>
      `,
    );
  });

  it('initializes the app', () => {
    createApp();
    app.init();
    expect(initViewSettings).toHaveBeenCalledWith({ pinia, streamUrl: '/reload' });
    expect(initFileBrowser).toHaveBeenCalled();
    expect(window.customElements.get('diff-file')).toBe(DiffFile);
    expect(window.customElements.get('diff-file-mounted')).toBe(DiffFileMounted);
  });

  it('streams remaining diffs', () => {
    createApp();
    app.streamRemainingDiffs();
    expect(useDiffsList().streamRemainingDiffs).toHaveBeenCalledWith('/stream');
  });
});
