import axios from '~/lib/utils/axios_utils';
import { compatH } from '~/lib/utils/vue3compat/compat_h';
import { initVueApp } from '~/lib/utils/vue3compat/init_vue_app';
import { normalizeRender } from '~/lib/utils/vue3compat/normalize_render';
import { pinia } from '~/pinia/instance';
import { DiffFile } from '~/rapid_diffs/web_components/diff_file';
import FileBrowserToggle from '~/diffs/components/file_browser_toggle.vue';
import { useMainContainer } from '~/pinia/global_stores/main_container';
import { keyboardShortcutsDisabled } from '~/behaviors/shortcuts/shortcuts_disabled';
import { keysFor, MR_FOCUS_FILE_BROWSER } from '~/behaviors/shortcuts/keybindings';
import { Mousetrap } from '~/lib/mousetrap';
import { useApp } from '~/rapid_diffs/stores/app';
import { useFileBrowser } from '~/diffs/stores/file_browser';
import { useDiffsList } from '~/rapid_diffs/stores/diffs_list';
import { useDiffsView } from '~/rapid_diffs/stores/diffs_view';
import { withLinkedFileUrlParams } from '~/rapid_diffs/utils/linked_file';
import FileBrowser from './file_browser.vue';
import FileBrowserDrawer from './file_browser_drawer.vue';
import FileBrowserDrawerToggle from './file_browser_drawer_toggle.vue';

function addFileLinks(diffFiles) {
  return diffFiles.map((diffFile) => {
    return Object.assign(diffFile, {
      href: withLinkedFileUrlParams(new URL(window.location), {
        oldPath: diffFile.old_path,
        newPath: diffFile.new_path,
        hash: diffFile.file_hash,
      }).toString(),
    });
  });
}

const loadFileBrowserData = async (diffFilesEndpoint, shouldSort) => {
  const { data } = await axios.get(diffFilesEndpoint);
  useFileBrowser().setTreeData(addFileLinks(data.diff_files), shouldSort);
};

const bindFocusShortcut = () => {
  const focusFileBrowser = () => {
    const store = useFileBrowser();

    if (useMainContainer().isCompact) {
      store.setFileBrowserDrawerVisibility(true);
    } else {
      store.setFileBrowserVisibility(true);
    }

    store.requestSearchFocus();
  };

  Mousetrap.bind(keysFor(MR_FOCUS_FILE_BROWSER), focusFileBrowser);
};

const initToggle = (el) => {
  initVueApp({
    el: document.querySelector('#js-page-breadcrumbs-extra'),
    name: 'FileBrowserDrawerToggleRoot',
    pinia,
    component: normalizeRender({
      name: 'FileBrowserDrawerToggleApp',
      computed: {
        visible() {
          return useMainContainer().isCompact && useApp().appVisible;
        },
      },
      render() {
        if (!this.visible) return null;

        return compatH(FileBrowserDrawerToggle);
      },
    }),
  });

  initVueApp({
    el,
    name: 'FileBrowserToggleRoot',
    pinia,
    component: normalizeRender({
      name: 'FileBrowserToggleApp',
      computed: {
        visible() {
          return !useMainContainer().isCompact;
        },
      },
      render() {
        if (!this.visible) return null;

        return compatH(FileBrowserToggle, { props: { bindFocusShortcut: false } });
      },
    }),
  });
};

const initBrowserComponent = async (el, shouldSort) => {
  initVueApp({
    el,
    name: 'FileBrowserRoot',
    pinia,
    component: normalizeRender({
      name: 'FileBrowserApp',
      render() {
        return compatH(useMainContainer().isCompact ? FileBrowserDrawer : FileBrowser, {
          props: {
            groupBlobsListItems: shouldSort,
            linkedFilePath: useDiffsList().linkedFilePath,
          },
          on: {
            'click-file': (file) => {
              const diffsView = useDiffsView(pinia);

              if (diffsView.singleFileMode) {
                const index = useFileBrowser(pinia).flatBlobsList.findIndex(
                  (entry) => entry.fileHash === file.fileHash,
                );

                if (index >= 0) diffsView.goToFile(index);
                return;
              }

              DiffFile.findByFileHash(file.fileHash).selectFile();
            },
          },
        });
      },
    }),
  });
};

export async function initFileBrowser({ toggleTarget, browserTarget, appData }) {
  initToggle(toggleTarget);
  if (!keyboardShortcutsDisabled()) bindFocusShortcut();
  useFileBrowser().initTreeList();
  await loadFileBrowserData(appData.diffFilesEndpoint, appData.shouldSortMetadataFiles);
  initBrowserComponent(browserTarget, appData.shouldSortMetadataFiles);
}
