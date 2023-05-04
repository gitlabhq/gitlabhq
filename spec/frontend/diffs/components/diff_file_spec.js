import { shallowMount } from '@vue/test-utils';
import MockAdapter from 'axios-mock-adapter';
import Vue, { nextTick } from 'vue';
import Vuex from 'vuex';

import DiffContentComponent from 'jh_else_ce/diffs/components/diff_content.vue';
import DiffFileComponent from '~/diffs/components/diff_file.vue';
import DiffFileHeaderComponent from '~/diffs/components/diff_file_header.vue';

import {
  EVT_EXPAND_ALL_FILES,
  EVT_PERF_MARK_DIFF_FILES_END,
  EVT_PERF_MARK_FIRST_DIFF_FILE_SHOWN,
} from '~/diffs/constants';
import eventHub from '~/diffs/event_hub';
import createDiffsStore from '~/diffs/store/modules';

import { diffViewerModes, diffViewerErrors } from '~/ide/constants';
import axios from '~/lib/utils/axios_utils';
import { scrollToElement } from '~/lib/utils/common_utils';
import { HTTP_STATUS_OK } from '~/lib/utils/http_status';
import createNotesStore from '~/notes/stores/modules';
import { getDiffFileMock } from '../mock_data/diff_file';
import diffFileMockDataUnreadable from '../mock_data/diff_file_unreadable';

jest.mock('~/lib/utils/common_utils');

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

function createComponent({ file, first = false, last = false, options = {}, props = {} }) {
  Vue.use(Vuex);

  const store = new Vuex.Store({
    ...createNotesStore(),
    modules: {
      diffs: createDiffsStore(),
    },
  });

  store.state.diffs.diffFiles = [file];

  const wrapper = shallowMount(DiffFileComponent, {
    store,
    propsData: {
      file,
      canCurrentUserFork: false,
      viewDiffsFileByFile: false,
      isFirstFile: first,
      isLastFile: last,
      ...props,
    },
    ...options,
  });

  return {
    wrapper,
    store,
  };
}

const findDiffHeader = (wrapper) => wrapper.findComponent(DiffFileHeaderComponent);
const findDiffContentArea = (wrapper) => wrapper.find('[data-testid="content-area"]');
const findLoader = (wrapper) => wrapper.find('[data-testid="loader-icon"]');
const findToggleButton = (wrapper) => wrapper.find('[data-testid="expand-button"]');

const toggleFile = (wrapper) => findDiffHeader(wrapper).vm.$emit('toggleFile');
const getReadableFile = () => getDiffFileMock();
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
  let axiosMock;

  beforeEach(() => {
    axiosMock = new MockAdapter(axios);
    ({ wrapper, store } = createComponent({ file: getReadableFile() }));
  });

  afterEach(() => {
    axiosMock.restore();
  });

  describe('bus events', () => {
    beforeEach(() => {
      jest.spyOn(eventHub, '$emit').mockImplementation(() => {});
    });

    describe('during mount', () => {
      it.each`
        first    | last     | events                                                                 | file
        ${false} | ${false} | ${[]}                                                                  | ${{ inlineLines: [], parallelLines: [], readableText: true }}
        ${true}  | ${true}  | ${[]}                                                                  | ${{ inlineLines: [], parallelLines: [], readableText: true }}
        ${true}  | ${false} | ${[EVT_PERF_MARK_FIRST_DIFF_FILE_SHOWN]}                               | ${false}
        ${false} | ${true}  | ${[EVT_PERF_MARK_DIFF_FILES_END]}                                      | ${false}
        ${true}  | ${true}  | ${[EVT_PERF_MARK_FIRST_DIFF_FILE_SHOWN, EVT_PERF_MARK_DIFF_FILES_END]} | ${false}
      `(
        'emits the events $events based on the file and its position ({ first: $first, last: $last }) among all files',
        async ({ file, first, last, events }) => {
          if (file) {
            forceHasDiff({ store, ...file });
          }

          ({ wrapper, store } = createComponent({
            file: store.state.diffs.diffFiles[0],
            first,
            last,
          }));

          await nextTick();

          expect(eventHub.$emit).toHaveBeenCalledTimes(events.length);
          events.forEach((event) => {
            expect(eventHub.$emit).toHaveBeenCalledWith(event);
          });
        },
      );

      it('emits the "first file shown" and "files end" events when in File-by-File mode', async () => {
        ({ wrapper, store } = createComponent({
          file: getReadableFile(),
          first: false,
          last: false,
          props: {
            viewDiffsFileByFile: true,
          },
        }));

        await nextTick();

        expect(eventHub.$emit).toHaveBeenCalledTimes(2);
        expect(eventHub.$emit).toHaveBeenCalledWith(EVT_PERF_MARK_FIRST_DIFF_FILE_SHOWN);
        expect(eventHub.$emit).toHaveBeenCalledWith(EVT_PERF_MARK_DIFF_FILES_END);
      });
    });

    describe('after loading the diff', () => {
      it('indicates that it loaded the file', async () => {
        forceHasDiff({ store, inlineLines: [], parallelLines: [], readableText: true });
        ({ wrapper, store } = createComponent({
          file: store.state.diffs.diffFiles[0],
          first: true,
          last: true,
        }));

        jest.spyOn(wrapper.vm, 'loadCollapsedDiff').mockResolvedValue(getReadableFile());
        jest.spyOn(window, 'requestIdleCallback').mockImplementation((fn) => fn());

        makeFileAutomaticallyCollapsed(store);

        await nextTick(); // Wait for store updates to flow into the component

        toggleFile(wrapper);

        await nextTick(); // Wait for the load to resolve
        await nextTick(); // Wait for the idleCallback
        await nextTick(); // Wait for nextTick inside postRender

        expect(eventHub.$emit).toHaveBeenCalledTimes(2);
        expect(eventHub.$emit).toHaveBeenCalledWith(EVT_PERF_MARK_FIRST_DIFF_FILE_SHOWN);
        expect(eventHub.$emit).toHaveBeenCalledWith(EVT_PERF_MARK_DIFF_FILES_END);
      });
    });
  });

  describe('template', () => {
    it('should render component with file header, file content components', async () => {
      const el = wrapper.vm.$el;
      const { file_hash } = wrapper.vm.file;

      expect(el.id).toEqual(file_hash);
      expect(el.classList.contains('diff-file')).toEqual(true);

      expect(el.querySelectorAll('.diff-content.hidden').length).toEqual(0);
      expect(el.querySelector('.js-file-title')).toBeDefined();
      expect(wrapper.findComponent(DiffFileHeaderComponent).exists()).toBe(true);
      expect(el.querySelector('.js-syntax-highlight')).toBeDefined();

      markFileToBeRendered(store);

      await nextTick();

      expect(wrapper.findComponent(DiffContentComponent).exists()).toBe(true);
    });
  });

  describe('computed', () => {
    describe('showLocalFileReviews', () => {
      function setLoggedIn(bool) {
        window.gon.current_user_id = bool;
      }

      it.each`
        loggedIn | bool
        ${true}  | ${true}
        ${false} | ${false}
      `('should be $bool when { userIsLoggedIn: $loggedIn }', ({ loggedIn, bool }) => {
        setLoggedIn(loggedIn);

        ({ wrapper } = createComponent({
          props: {
            file: store.state.diffs.diffFiles[0],
          },
        }));

        expect(wrapper.vm.showLocalFileReviews).toBe(bool);
      });
    });
  });

  describe('collapsing', () => {
    describe(`\`${EVT_EXPAND_ALL_FILES}\` event`, () => {
      beforeEach(() => {
        jest.spyOn(wrapper.vm, 'handleToggle').mockImplementation(() => {});
      });

      it('performs the normal file toggle when the file is collapsed', async () => {
        makeFileAutomaticallyCollapsed(store);

        await nextTick();

        eventHub.$emit(EVT_EXPAND_ALL_FILES);

        expect(wrapper.vm.handleToggle).toHaveBeenCalledTimes(1);
      });

      it('does nothing when the file is not collapsed', async () => {
        eventHub.$emit(EVT_EXPAND_ALL_FILES);

        await nextTick();

        expect(wrapper.vm.handleToggle).not.toHaveBeenCalled();
      });
    });

    describe('user collapsed', () => {
      beforeEach(() => {
        makeFileManuallyCollapsed(store);
      });

      it('should not have any content at all', async () => {
        await nextTick();

        expect(findDiffContentArea(wrapper).element.children.length).toBe(0);
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

      it('should have the file content', () => {
        expect(wrapper.findComponent(DiffContentComponent).exists()).toBe(true);
      });

      it('should style the component so that it `.has-body` for layout purposes', () => {
        expect(wrapper.classes('has-body')).toBe(true);
      });
    });

    describe('toggle', () => {
      it('should update store state', () => {
        jest.spyOn(wrapper.vm.$store, 'dispatch').mockImplementation(() => {});

        toggleFile(wrapper);

        expect(wrapper.vm.$store.dispatch).toHaveBeenCalledWith('diffs/setFileCollapsedByUser', {
          filePath: wrapper.vm.file.file_path,
          collapsed: true,
        });
      });

      describe('scoll-to-top of file after collapse', () => {
        beforeEach(() => {
          jest.spyOn(wrapper.vm.$store, 'dispatch').mockImplementation(() => {});
        });

        it("scrolls to the top when the file is open, the users initiates the collapse, and there's a content block to scroll to", async () => {
          makeFileOpenByDefault(store);
          await nextTick();

          toggleFile(wrapper);

          expect(scrollToElement).toHaveBeenCalled();
        });

        it('does not scroll when the content block is missing', async () => {
          makeFileOpenByDefault(store);
          await nextTick();
          findDiffContentArea(wrapper).element.remove();

          toggleFile(wrapper);

          expect(scrollToElement).not.toHaveBeenCalled();
        });

        it("does not scroll if the user doesn't initiate the file collapse", async () => {
          makeFileOpenByDefault(store);
          await nextTick();

          wrapper.vm.handleToggle();

          expect(scrollToElement).not.toHaveBeenCalled();
        });

        it('does not scroll if the file is already collapsed', async () => {
          makeFileManuallyCollapsed(store);
          await nextTick();

          toggleFile(wrapper);

          expect(scrollToElement).not.toHaveBeenCalled();
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

          await nextTick();

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
        const { load_collapsed_diff_url } = store.state.diffs.diffFiles[0];
        axiosMock.onGet(load_collapsed_diff_url).reply(HTTP_STATUS_OK, getReadableFile());
        makeFileAutomaticallyCollapsed(store);
        wrapper.vm.requestDiff();

        await nextTick();

        expect(findLoader(wrapper).exists()).toBe(true);
      });
    });

    describe('general (other) collapsed', () => {
      it('should be expandable for unreadable files', async () => {
        ({ wrapper, store } = createComponent({ file: getUnreadableFile() }));
        makeFileAutomaticallyCollapsed(store);

        await nextTick();

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

          await nextTick();

          expect(wrapper.classes('has-body')).toBe(true);
          expect(wrapper.findComponent(DiffContentComponent).exists()).toBe(true);
          expect(wrapper.findComponent(DiffContentComponent).isVisible()).toBe(true);
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

      await nextTick();

      const button = wrapper.find('[data-testid="blob-button"]');

      expect(wrapper.text()).toContain('Changes are too large to be shown.');
      expect(button.html()).toContain('View file @');
      expect(button.attributes('href')).toBe('/file/view/path');
    });
  });

  it('loads collapsed file on mounted when single file mode is enabled', async () => {
    const file = {
      ...getReadableFile(),
      load_collapsed_diff_url: '/diff_for_path',
      highlighted_diff_lines: [],
      parallel_diff_lines: [],
      viewer: { name: 'collapsed', automaticallyCollapsed: true },
    };

    axiosMock.onGet(file.load_collapsed_diff_url).reply(HTTP_STATUS_OK, getReadableFile());

    ({ wrapper, store } = createComponent({ file, props: { viewDiffsFileByFile: true } }));

    await nextTick();

    expect(findLoader(wrapper).exists()).toBe(true);
  });

  describe('merge conflicts', () => {
    it('does not render conflict alert', () => {
      const file = {
        ...getReadableFile(),
        conflict_type: null,
        renderIt: true,
      };

      ({ wrapper, store } = createComponent({ file }));

      expect(wrapper.find('[data-testid="conflictsAlert"]').exists()).toBe(false);
    });

    it('renders conflict alert when conflict_type is present', () => {
      const file = {
        ...getReadableFile(),
        conflict_type: 'both_modified',
        renderIt: true,
      };

      ({ wrapper, store } = createComponent({ file }));

      expect(wrapper.find('[data-testid="conflictsAlert"]').exists()).toBe(true);
    });
  });
});
