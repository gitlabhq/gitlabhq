import { resetHTMLFixture, setHTMLFixture } from 'helpers/fixtures';
import store from '~/mr_notes/stores';
import { initFileBrowser } from '~/rapid_diffs/app/init_file_browser';
import createEventHub from '~/helpers/event_hub_factory';
import waitForPromises from 'helpers/wait_for_promises';
import { DiffFile } from '~/rapid_diffs/diff_file';

jest.mock('~/rapid_diffs/app/file_browser.vue', () => ({
  props: jest.requireActual('~/rapid_diffs/app/file_browser.vue').default.props,
  render(h) {
    return h('div', {
      attrs: {
        'data-file-browser-component': true,
        'data-loaded-files': JSON.stringify(this.loadedFiles),
      },
      on: {
        click: () => {
          this.$emit('clickFile', { fileHash: 'first' });
        },
      },
    });
  },
}));

describe('Init file browser', () => {
  let dispatch;

  const getMountElement = () => document.querySelector('[data-file-browser]');
  const getFileBrowser = () => document.querySelector('[data-file-browser-component]');

  beforeEach(() => {
    dispatch = jest.spyOn(store, 'dispatch').mockResolvedValue();
    window.mrTabs = { eventHub: createEventHub() };
    setHTMLFixture(
      `
        <div data-file-browser data-metadata-endpoint="/metadata"></div>
        <diff-file id="first"></diff-file>
      `,
    );
  });

  beforeAll(() => {
    customElements.define('diff-file', DiffFile);
  });

  afterEach(() => {
    resetHTMLFixture();
  });

  it('sets metadata endpoint', () => {
    initFileBrowser();
    expect(store.state.diffs.endpointMetadata).toBe(getMountElement().dataset.metadataEndpoint);
  });

  it('fetches metadata', () => {
    initFileBrowser();
    expect(dispatch).toHaveBeenCalledWith('diffs/fetchDiffFilesMeta');
  });

  it('provides already loaded files', async () => {
    initFileBrowser();
    await waitForPromises();
    expect(JSON.parse(getFileBrowser().dataset.loadedFiles)).toStrictEqual({ first: true });
  });

  it('handles file clicks', async () => {
    const selectFile = jest.fn();
    const spy = jest.spyOn(DiffFile, 'findByFileHash').mockReturnValue({ selectFile });
    initFileBrowser();
    await waitForPromises();
    getFileBrowser().click();
    expect(spy).toHaveBeenCalledWith('first');
    expect(selectFile).toHaveBeenCalled();
  });
});
