import MockAdapter from 'axios-mock-adapter';
import { setActivePinia } from 'pinia';
import { nextTick } from 'vue';
import axios from '~/lib/utils/axios_utils';
import { resetHTMLFixture, setHTMLFixture } from 'helpers/fixtures';
import { initFileBrowser } from '~/rapid_diffs/app/init_file_browser';
import { DiffFile } from '~/rapid_diffs/diff_file';
import { HTTP_STATUS_OK } from '~/lib/utils/http_status';
import { useViewport } from '~/pinia/global_stores/viewport';
import { pinia } from '~/pinia/instance';
import { useApp } from '~/rapid_diffs/stores/app';

jest.mock('~/rapid_diffs/app/file_browser.vue', () => ({
  props: jest.requireActual('~/rapid_diffs/app/file_browser.vue').default.props,
  render(h) {
    return h('div', {
      attrs: {
        'data-file-browser-component': true,
        'data-group-blobs-list-items': JSON.stringify(this.groupBlobsListItems),
      },
      on: {
        click: () => {
          this.$emit('clickFile', { fileHash: 'first' });
        },
      },
    });
  },
}));

jest.mock('~/rapid_diffs/app/file_browser_drawer.vue', () => ({
  props: jest.requireActual('~/rapid_diffs/app/file_browser_drawer.vue').default.props,
  render(h) {
    return h('div', {
      attrs: {
        'data-file-browser-drawer-component': true,
        'data-group-blobs-list-items': JSON.stringify(this.groupBlobsListItems),
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

jest.mock('~/rapid_diffs/app/file_browser_drawer_toggle.vue', () => ({
  render(h) {
    return h('div', {
      attrs: {
        'data-file-browser-drawer-toggle-component': true,
      },
    });
  },
}));

describe('Init file browser', () => {
  let mockAxios;
  let appData;

  const getFileBrowserTarget = () => document.querySelector('[data-file-browser]');
  const getFileBrowserToggleTarget = () => document.querySelector('[data-file-browser-toggle]');
  const getFileBrowser = () => document.querySelector('[data-file-browser-component]');
  const getFileBrowserDrawer = () => document.querySelector('[data-file-browser-drawer-component]');
  const getFileBrowserToggle = () => document.querySelector('[data-file-browser-toggle-component]');
  const getFileBrowserDrawerToggle = () =>
    document.querySelector('[data-file-browser-drawer-toggle-component]');

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

  const initAppData = ({
    diffFilesEndpoint = '/diff-files-metadata',
    shouldSortMetadataFiles = true,
  } = {}) => {
    appData = {
      diffFilesEndpoint,
      shouldSortMetadataFiles,
    };
  };

  const init = () => {
    return initFileBrowser({
      toggleTarget: getFileBrowserToggleTarget(),
      browserTarget: getFileBrowserTarget(),
      appData,
    });
  };

  beforeEach(() => {
    setActivePinia(pinia);
    initAppData();
    useViewport().reset();
    useApp().$reset();

    mockAxios = new MockAdapter(axios);
    mockAxios
      .onGet(appData.diffFilesEndpoint)
      .reply(HTTP_STATUS_OK, { diff_files: createDiffFiles() });

    setHTMLFixture(`
      <div id="js-page-breadcrumbs-extra"></div>
      <div data-file-browser-toggle></div>
      <div data-file-browser data-metadata-endpoint="/metadata"></div>
      <diff-file data-file-data="{}" id="first"><div></div></diff-file>
    `);

    DiffFile.getAll().forEach((file) =>
      file.mount({ adapterConfig: {}, appData: {}, unobserve: jest.fn() }),
    );
  });

  beforeAll(() => {
    customElements.define('diff-file', DiffFile);
  });

  afterEach(() => {
    resetHTMLFixture();
  });

  describe.each`
    isNarrowScreen | getBrowserElement       | getBrowserToggleElement
    ${false}       | ${getFileBrowser}       | ${getFileBrowserToggle}
    ${true}        | ${getFileBrowserDrawer} | ${getFileBrowserDrawerToggle}
  `(
    'when narrow screen is $isNarrowScreen',
    ({ isNarrowScreen, getBrowserElement, getBrowserToggleElement }) => {
      beforeEach(() => {
        useViewport().updateIsNarrow(isNarrowScreen);
      });

      it('mounts the components', async () => {
        await init();

        expect(getBrowserElement()).not.toBe(null);
        expect(getBrowserToggleElement()).not.toBe(null);
      });

      it('handles file clicks', async () => {
        const selectFile = jest.fn();
        const spy = jest.spyOn(DiffFile, 'findByFileHash').mockReturnValue({ selectFile });

        await init();

        const fileBrowser = getBrowserElement();
        fileBrowser.click();

        expect(spy).toHaveBeenCalledWith('first');
        expect(selectFile).toHaveBeenCalled();
      });

      it('passes sorting configuration to components', async () => {
        await init();
        expect(document.querySelector('[data-group-blobs-list-items="true"]')).not.toBe(null);
      });

      it('disables sorting when configured', async () => {
        initAppData({ shouldSortMetadataFiles: false });
        await init();
        expect(document.querySelector('[data-group-blobs-list-items="false"]')).not.toBe(null);
      });
    },
  );

  it('loads diff files data', async () => {
    await init();

    expect(mockAxios.history.get).toHaveLength(1);
    expect(mockAxios.history.get[0].url).toBe('/diff-files-metadata');
  });

  it('hides drawer toggle when app is hidden', async () => {
    useViewport().updateIsNarrow(true);
    await init();
    useApp().appVisible = false;
    await nextTick();
    expect(getFileBrowserDrawerToggle()).toBe(null);
  });
});
