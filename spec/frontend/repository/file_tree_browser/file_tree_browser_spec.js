import Vue from 'vue';
import { shallowMount } from '@vue/test-utils';
import { createTestingPinia } from '@pinia/testing';
import { PiniaVuePlugin } from 'pinia';
import FileTreeBrowser, {
  TREE_WIDTH,
  FILE_TREE_BROWSER_STORAGE_KEY,
} from '~/repository/file_tree_browser/file_tree_browser.vue';
import FileBrowserHeight from '~/diffs/components/file_browser_height.vue';
import PanelResizer from '~/vue_shared/components/panel_resizer.vue';
import { useLocalStorageSpy } from 'helpers/local_storage_helper';
import { useFileTreeBrowserVisibility } from '~/repository/stores/file_tree_browser_visibility';

Vue.use(PiniaVuePlugin);

describe('FileTreeBrowser', () => {
  let wrapper;
  let pinia;
  let fileTreeBrowserStore;

  useLocalStorageSpy();

  const findFileBrowserHeight = () => wrapper.findComponent(FileBrowserHeight);
  const findPanelResizer = () => wrapper.findComponent(PanelResizer);

  afterEach(() => {
    localStorage.clear();
  });

  const createComponent = (routeName = 'blobPathDecoded') => {
    wrapper = shallowMount(FileTreeBrowser, {
      propsData: {
        projectPath: 'group/project',
        currentRef: 'main',
        refType: 'branch',
      },
      mocks: {
        $route: {
          name: routeName,
        },
      },
      pinia,
    });
  };

  describe('when not on project overview page', () => {
    beforeEach(() => {
      pinia = createTestingPinia({ stubActions: false });
      fileTreeBrowserStore = useFileTreeBrowserVisibility();
      fileTreeBrowserStore.setFileTreeVisibility(true);
      createComponent();
    });

    it('renders the file browser height component', () => {
      expect(findFileBrowserHeight().exists()).toBe(true);
      expect(findFileBrowserHeight().attributes('style')).toBe(`--tree-width: ${TREE_WIDTH}px;`);
    });

    describe('PanelResizer component', () => {
      it('renders the panel resizer component', () => {
        expect(findPanelResizer().exists()).toBe(true);
      });

      it('updates tree width when panel resizer emits update:size', async () => {
        const newWidth = 400;

        await findPanelResizer().vm.$emit('update:size', newWidth);

        expect(findFileBrowserHeight().attributes('style')).toBe(`--tree-width: ${newWidth}px;`);
      });

      it('saves tree width preference when panel resizer emits resize-end', async () => {
        const newWidth = 400;

        await findPanelResizer().vm.$emit('resize-end', newWidth);

        expect(localStorage.setItem).toHaveBeenCalledWith(FILE_TREE_BROWSER_STORAGE_KEY, newWidth);
        expect(findFileBrowserHeight().attributes('style')).toBe(`--tree-width: ${newWidth}px;`);
      });
    });

    describe('localStorage handling', () => {
      it('restores tree width from localStorage on component creation', () => {
        const storedWidth = 350;
        localStorage.setItem(FILE_TREE_BROWSER_STORAGE_KEY, storedWidth.toString());

        createComponent();

        expect(localStorage.getItem).toHaveBeenCalledWith(FILE_TREE_BROWSER_STORAGE_KEY);
        expect(findFileBrowserHeight().attributes('style')).toBe(`--tree-width: ${storedWidth}px;`);
      });

      it('uses default width when localStorage is empty', () => {
        createComponent();

        expect(findFileBrowserHeight().attributes('style')).toBe(`--tree-width: ${TREE_WIDTH}px;`);
      });
    });
  });
});
