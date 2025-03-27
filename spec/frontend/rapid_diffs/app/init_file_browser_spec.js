import MockAdapter from 'axios-mock-adapter';
import axios from 'axios';
import { resetHTMLFixture, setHTMLFixture } from 'helpers/fixtures';
import { initFileBrowser } from '~/rapid_diffs/app/init_file_browser';
import createEventHub from '~/helpers/event_hub_factory';
import waitForPromises from 'helpers/wait_for_promises';
import { DiffFile } from '~/rapid_diffs/diff_file';
import { HTTP_STATUS_OK } from '~/lib/utils/http_status';
import store from '~/mr_notes/stores';
import { SET_TREE_DATA } from '~/diffs/store/mutation_types';

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
  const diffFilesEndpoint = '/diff-files-metadata';
  const getFileBrowser = () => document.querySelector('[data-file-browser-component]');
  const createDiffFiles = () => [
    {
      conflict_type: null,
      added_lines: 3,
      removed_lines: 3,
      new_path: '.gitlab/ci/as-if-foss.gitlab-ci.yml',
      old_path: '.gitlab/ci/as-if-foss.gitlab-ci.yml',
      new_file: false,
      deleted_file: false,
      submodule: false,
      file_identifier_hash: 'b7e76d4365caabb99ccd17ed3b871470df920aa2',
      file_hash: '6e9c59ba18901dfd9c99bb432c515d498f49690d',
    },
    {
      conflict_type: null,
      added_lines: 2,
      removed_lines: 1,
      new_path: '.gitlab/ci/setup.gitlab-ci.yml',
      old_path: '.gitlab/ci/setup.gitlab-ci.yml',
      new_file: false,
      deleted_file: false,
      submodule: false,
      file_identifier_hash: '14f542137408c86fa0fd8df56e4775855dc3ff53',
      file_hash: '12dc3d87e90313d83a236a944f8a4869f1dc97e2',
    },
  ];
  let mockAxios;
  let commit;

  beforeEach(() => {
    window.mrTabs = { eventHub: createEventHub() };
    mockAxios = new MockAdapter(axios);
    mockAxios.onGet(diffFilesEndpoint).reply(HTTP_STATUS_OK, { diff_files: createDiffFiles() });
    commit = jest.spyOn(store, 'commit');
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

  it('mounts the component', async () => {
    await initFileBrowser(diffFilesEndpoint);
    expect(getFileBrowser()).not.toBe(null);
  });

  it('loads diff files data', async () => {
    await initFileBrowser(diffFilesEndpoint);
    expect(commit).toHaveBeenCalledWith(
      `diffs/${SET_TREE_DATA}`,
      expect.objectContaining({
        tree: expect.any(Array),
        treeEntries: expect.any(Object),
      }),
    );
  });

  it('handles file clicks', async () => {
    const selectFile = jest.fn();
    const spy = jest.spyOn(DiffFile, 'findByFileHash').mockReturnValue({ selectFile });
    initFileBrowser(diffFilesEndpoint);
    await waitForPromises();
    getFileBrowser().click();
    expect(spy).toHaveBeenCalledWith('first');
    expect(selectFile).toHaveBeenCalled();
  });

  it('shows file browser toggle', async () => {
    initFileBrowser(diffFilesEndpoint);
    await waitForPromises();
    expect(document.querySelector('[data-file-browser-toggle-component]')).not.toBe(null);
  });
});
