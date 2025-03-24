import { resetHTMLFixture, setHTMLFixture } from 'helpers/fixtures';
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
      },
      on: {
        click: () => {
          this.$emit('clickFile', { fileHash: 'first' });
        },
      },
    });
  },
}));

jest.mock('~/diffs/components/file_browser_toggle.vue', () => ({
  render(h) {
    return h('div', {
      attrs: {
        'data-file-browser-toggle-component': true,
      },
    });
  },
}));

describe('Init file browser', () => {
  const getFileBrowser = () => document.querySelector('[data-file-browser-component]');

  beforeEach(() => {
    window.mrTabs = { eventHub: createEventHub() };
    setHTMLFixture(
      `
        <div data-file-browser-toggle></div>
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

  it('mounts the component', () => {
    initFileBrowser();
    expect(getFileBrowser()).not.toBe(null);
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

  it('shows file browser toggle', async () => {
    initFileBrowser();
    await waitForPromises();
    expect(document.querySelector('[data-file-browser-toggle-component]')).not.toBe(null);
  });
});
