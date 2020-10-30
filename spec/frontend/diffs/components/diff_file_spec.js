import Vuex from 'vuex';
import { shallowMount, createLocalVue } from '@vue/test-utils';

import createDiffsStore from '~/diffs/store/modules';
import diffFileMockDataReadable from '../mock_data/diff_file';
import diffFileMockDataUnreadable from '../mock_data/diff_file_unreadable';

import DiffFileComponent from '~/diffs/components/diff_file.vue';
import DiffFileHeaderComponent from '~/diffs/components/diff_file_header.vue';
import DiffContentComponent from '~/diffs/components/diff_content.vue';

import eventHub from '~/diffs/event_hub';

import { diffViewerModes, diffViewerErrors } from '~/ide/constants';

function changeViewer(store, index, { automaticallyCollapsed, manuallyCollapsed, name }) {
  const file = store.state.diffs.diffFiles[index];
  const newViewer = {
    ...file.viewer,
  };

  if (automaticallyCollapsed !== undefined) {
    newViewer.automaticallyCollapsed = automaticallyCollapsed;
  }

  if (manuallyCollapsed !== undefined) {
    newViewer.manuallyCollapsed = manuallyCollapsed;
  }

  if (name !== undefined) {
    newViewer.name = name;
  }

  Object.assign(file, {
    viewer: newViewer,
  });
}

function forceHasDiff({ store, index = 0, inlineLines, parallelLines, readableText }) {
  const file = store.state.diffs.diffFiles[index];

  Object.assign(file, {
    highlighted_diff_lines: inlineLines,
    parallel_diff_lines: parallelLines,
    blob: {
      ...file.blob,
      readable_text: readableText,
    },
  });
}

function markFileToBeRendered(store, index = 0) {
  const file = store.state.diffs.diffFiles[index];

  Object.assign(file, {
    renderIt: true,
  });
}

function createComponent({ file }) {
  const localVue = createLocalVue();

  localVue.use(Vuex);

  const store = new Vuex.Store({
    modules: {
      diffs: createDiffsStore(),
    },
  });

  store.state.diffs.diffFiles = [file];

  const wrapper = shallowMount(DiffFileComponent, {
    store,
    localVue,
    propsData: {
      file,
      canCurrentUserFork: false,
      viewDiffsFileByFile: false,
    },
  });

  return {
    localVue,
    wrapper,
    store,
  };
}

const findDiffHeader = wrapper => wrapper.find(DiffFileHeaderComponent);
const findDiffContentArea = wrapper => wrapper.find('[data-testid="content-area"]');
const findLoader = wrapper => wrapper.find('[data-testid="loader-icon"]');
const findToggleButton = wrapper => wrapper.find('[data-testid="expand-button"]');

const toggleFile = wrapper => findDiffHeader(wrapper).vm.$emit('toggleFile');
const isDisplayNone = element => element.style.display === 'none';
const getReadableFile = () => JSON.parse(JSON.stringify(diffFileMockDataReadable));
const getUnreadableFile = () => JSON.parse(JSON.stringify(diffFileMockDataUnreadable));

const makeFileAutomaticallyCollapsed = (store, index = 0) =>
  changeViewer(store, index, { automaticallyCollapsed: true, manuallyCollapsed: null });
const makeFileOpenByDefault = (store, index = 0) =>
  changeViewer(store, index, { automaticallyCollapsed: false, manuallyCollapsed: null });
const makeFileManuallyCollapsed = (store, index = 0) =>
  changeViewer(store, index, { automaticallyCollapsed: false, manuallyCollapsed: true });
const changeViewerType = (store, newType, index = 0) =>
  changeViewer(store, index, { name: diffViewerModes[newType] });

describe('DiffFile', () => {
  let wrapper;
  let store;

  beforeEach(() => {
    ({ wrapper, store } = createComponent({ file: getReadableFile() }));
  });

  afterEach(() => {
    wrapper.destroy();
  });

  describe('template', () => {
    it('should render component with file header, file content components', async () => {
      const el = wrapper.vm.$el;
      const { file_hash } = wrapper.vm.file;

      expect(el.id).toEqual(file_hash);
      expect(el.classList.contains('diff-file')).toEqual(true);

      expect(el.querySelectorAll('.diff-content.hidden').length).toEqual(0);
      expect(el.querySelector('.js-file-title')).toBeDefined();
      expect(wrapper.find(DiffFileHeaderComponent).exists()).toBe(true);
      expect(el.querySelector('.js-syntax-highlight')).toBeDefined();

      markFileToBeRendered(store);

      await wrapper.vm.$nextTick();

      expect(wrapper.find(DiffContentComponent).exists()).toBe(true);
    });
  });

  describe('collapsing', () => {
    describe('`mr:diffs:expandAllFiles` event', () => {
      beforeEach(() => {
        jest.spyOn(wrapper.vm, 'handleToggle').mockImplementation(() => {});
      });

      it('performs the normal file toggle when the file is collapsed', async () => {
        makeFileAutomaticallyCollapsed(store);

        await wrapper.vm.$nextTick();

        eventHub.$emit('mr:diffs:expandAllFiles');

        expect(wrapper.vm.handleToggle).toHaveBeenCalledTimes(1);
      });

      it('does nothing when the file is not collapsed', async () => {
        eventHub.$emit('mr:diffs:expandAllFiles');

        await wrapper.vm.$nextTick();

        expect(wrapper.vm.handleToggle).not.toHaveBeenCalled();
      });
    });

    describe('user collapsed', () => {
      beforeEach(() => {
        makeFileManuallyCollapsed(store);
      });

      it('should not have any content at all', async () => {
        await wrapper.vm.$nextTick();

        Array.from(findDiffContentArea(wrapper).element.children).forEach(child => {
          expect(isDisplayNone(child)).toBe(true);
        });
      });

      it('should not have the class `has-body` to present the header differently', () => {
        expect(wrapper.classes('has-body')).toBe(false);
      });
    });

    describe('automatically collapsed', () => {
      beforeEach(() => {
        makeFileAutomaticallyCollapsed(store);
      });

      it('should show the collapsed file warning with expansion button', () => {
        expect(findDiffContentArea(wrapper).html()).toContain(
          'Files with large changes are collapsed by default.',
        );
        expect(findToggleButton(wrapper).exists()).toBe(true);
      });

      it('should style the component so that it `.has-body` for layout purposes', () => {
        expect(wrapper.classes('has-body')).toBe(true);
      });
    });

    describe('not collapsed', () => {
      beforeEach(() => {
        makeFileOpenByDefault(store);
        markFileToBeRendered(store);
      });

      it('should have the file content', async () => {
        expect(wrapper.find(DiffContentComponent).exists()).toBe(true);
      });

      it('should style the component so that it `.has-body` for layout purposes', () => {
        expect(wrapper.classes('has-body')).toBe(true);
      });
    });

    describe('toggle', () => {
      it('should update store state', async () => {
        jest.spyOn(wrapper.vm.$store, 'dispatch').mockImplementation(() => {});

        toggleFile(wrapper);

        expect(wrapper.vm.$store.dispatch).toHaveBeenCalledWith('diffs/setFileCollapsedByUser', {
          filePath: wrapper.vm.file.file_path,
          collapsed: true,
        });
      });

      describe('fetch collapsed diff', () => {
        const prepFile = async (inlineLines, parallelLines, readableText) => {
          forceHasDiff({
            store,
            inlineLines,
            parallelLines,
            readableText,
          });

          await wrapper.vm.$nextTick();

          toggleFile(wrapper);
        };

        beforeEach(() => {
          jest.spyOn(wrapper.vm, 'requestDiff').mockImplementation(() => {});

          makeFileAutomaticallyCollapsed(store);
        });

        it.each`
          inlineLines | parallelLines | readableText
          ${[1]}      | ${[1]}        | ${true}
          ${[]}       | ${[1]}        | ${true}
          ${[1]}      | ${[]}         | ${true}
          ${[1]}      | ${[1]}        | ${false}
          ${[]}       | ${[]}         | ${false}
        `(
          'does not make a request to fetch the diff for a diff file like { inline: $inlineLines, parallel: $parallelLines, readableText: $readableText }',
          async ({ inlineLines, parallelLines, readableText }) => {
            await prepFile(inlineLines, parallelLines, readableText);

            expect(wrapper.vm.requestDiff).not.toHaveBeenCalled();
          },
        );

        it.each`
          inlineLines | parallelLines | readableText
          ${[]}       | ${[]}         | ${true}
        `(
          'makes a request to fetch the diff for a diff file like { inline: $inlineLines, parallel: $parallelLines, readableText: $readableText }',
          async ({ inlineLines, parallelLines, readableText }) => {
            await prepFile(inlineLines, parallelLines, readableText);

            expect(wrapper.vm.requestDiff).toHaveBeenCalled();
          },
        );
      });
    });

    describe('loading', () => {
      it('should have loading icon while loading a collapsed diffs', async () => {
        makeFileAutomaticallyCollapsed(store);
        wrapper.vm.isLoadingCollapsedDiff = true;

        await wrapper.vm.$nextTick();

        expect(findLoader(wrapper).exists()).toBe(true);
      });
    });

    describe('general (other) collapsed', () => {
      it('should be expandable for unreadable files', async () => {
        ({ wrapper, store } = createComponent({ file: getUnreadableFile() }));
        makeFileAutomaticallyCollapsed(store);

        await wrapper.vm.$nextTick();

        expect(findDiffContentArea(wrapper).html()).toContain(
          'Files with large changes are collapsed by default.',
        );
        expect(findToggleButton(wrapper).exists()).toBe(true);
      });

      it.each`
        mode
        ${'renamed'}
        ${'mode_changed'}
      `(
        'should render the DiffContent component for files whose mode is $mode',
        async ({ mode }) => {
          makeFileOpenByDefault(store);
          markFileToBeRendered(store);
          changeViewerType(store, mode);

          await wrapper.vm.$nextTick();

          expect(wrapper.classes('has-body')).toBe(true);
          expect(wrapper.find(DiffContentComponent).exists()).toBe(true);
          expect(wrapper.find(DiffContentComponent).isVisible()).toBe(true);
        },
      );
    });
  });

  describe('too large diff', () => {
    it('should have too large warning and blob link', async () => {
      const file = store.state.diffs.diffFiles[0];
      const BLOB_LINK = '/file/view/path';

      Object.assign(store.state.diffs.diffFiles[0], {
        ...file,
        view_path: BLOB_LINK,
        renderIt: true,
        viewer: {
          ...file.viewer,
          error: diffViewerErrors.too_large,
          error_message: 'This source diff could not be displayed because it is too large',
        },
      });

      await wrapper.vm.$nextTick();

      expect(wrapper.vm.$el.innerText).toContain(
        'This source diff could not be displayed because it is too large',
      );
    });
  });
});
