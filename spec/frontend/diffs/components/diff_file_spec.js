import MockAdapter from 'axios-mock-adapter';
import Vue, { nextTick } from 'vue';
// eslint-disable-next-line no-restricted-imports
import Vuex from 'vuex';
import { GlSprintf } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';

import waitForPromises from 'helpers/wait_for_promises';
import { sprintf } from '~/locale';
import { createAlert } from '~/alert';

import DiffContentComponent from 'jh_else_ce/diffs/components/diff_content.vue';
import DiffFileComponent from '~/diffs/components/diff_file.vue';
import DiffFileHeaderComponent from '~/diffs/components/diff_file_header.vue';
import DiffFileDiscussionExpansion from '~/diffs/components/diff_file_discussion_expansion.vue';
import DiffFileDrafts from '~/batch_comments/components/diff_file_drafts.vue';

import {
  EVT_DISCUSSIONS_ASSIGNED,
  EVT_EXPAND_ALL_FILES,
  EVT_PERF_MARK_DIFF_FILES_END,
  EVT_PERF_MARK_FIRST_DIFF_FILE_SHOWN,
  FILE_DIFF_POSITION_TYPE,
} from '~/diffs/constants';
import eventHub from '~/diffs/event_hub';

import { diffViewerModes, diffViewerErrors } from '~/ide/constants';
import axios from '~/lib/utils/axios_utils';
import { clearDraft } from '~/lib/utils/autosave';
import { scrollToElement, isElementStuck } from '~/lib/utils/common_utils';
import { HTTP_STATUS_OK } from '~/lib/utils/http_status';
import createNotesStore from '~/notes/stores/modules';
import diffsModule from '~/diffs/store/modules';
import { SOMETHING_WENT_WRONG, SAVING_THE_COMMENT_FAILED } from '~/diffs/i18n';
import diffLineNoteFormMixin from '~/notes/mixins/diff_line_note_form';
import notesEventHub from '~/notes/event_hub';
import { getDiffFileMock } from '../mock_data/diff_file';
import diffFileMockDataUnreadable from '../mock_data/diff_file_unreadable';
import diffsMockData from '../mock_data/merge_request_diffs';

jest.mock('~/lib/utils/common_utils');
jest.mock('~/lib/utils/autosave');
jest.mock('~/alert');
jest.mock('~/notes/mixins/diff_line_note_form', () => ({
  methods: {
    addToReview: jest.fn(),
  },
}));

Vue.use(Vuex);

const saveDiffDiscussionMock = jest.fn();
const prefetchFileNeighborsMock = jest.fn();

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

function forceHasDiff({ store, index = 0, inlineLines, parallelLines, expandable }) {
  const file = store.state.diffs.diffFiles[index];

  Object.assign(file, {
    highlighted_diff_lines: inlineLines,
    parallel_diff_lines: parallelLines,
    blob: {
      ...file.blob,
    },
    viewer: {
      ...file.viewer,
      expandable,
    },
  });
}

function markFileToBeRendered(store, index = 0) {
  const file = store.state.diffs.diffFiles[index];

  Object.assign(file, {
    renderIt: true,
  });
}

const findDiffHeader = (wrapper) => wrapper.findComponent(DiffFileHeaderComponent);
const findDiffContentArea = (wrapper) => wrapper.findByTestId('content-area');
const findLoader = (wrapper) => wrapper.findByTestId('loader-icon');
const findToggleButton = (wrapper) => wrapper.findByTestId('expand-button');
const findNoteForm = (wrapper) => wrapper.findByTestId('file-note-form');

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

// eslint-disable-next-line max-params
const triggerSaveNote = (wrapper, note, parent, error) =>
  findNoteForm(wrapper).vm.$emit('handleFormUpdate', note, parent, error);

// eslint-disable-next-line max-params
const triggerSaveDraftNote = (wrapper, note, parent, error) =>
  findNoteForm(wrapper).vm.$emit('handleFormUpdateAddToReview', note, false, parent, error);

describe('DiffFile', () => {
  let wrapper;
  let store;
  let axiosMock;
  let toggleFileDiscussionMock;

  function createComponent({
    file = getReadableFile(),
    first = false,
    last = false,
    options = {},
    props = {},
    getters = {},
  } = {}) {
    toggleFileDiscussionMock = jest.fn();

    const diffs = diffsModule();
    const notes = createNotesStore();
    diffs.actions = {
      ...diffs.actions,
      toggleFileDiscussion: toggleFileDiscussionMock,
      prefetchFileNeighbors: prefetchFileNeighborsMock,
      saveDiffDiscussion: saveDiffDiscussionMock,
    };

    diffs.getters = {
      ...diffs.getters,
      diffCompareDropdownTargetVersions: () => [],
      diffCompareDropdownSourceVersions: () => [],
      ...getters.diffs,
    };
    notes.getters = {
      ...notes.getters,
      isLoggedIn: () => false,
      ...getters.notes,
    };

    store = new Vuex.Store({
      ...notes,
      modules: { diffs },
    });

    store.state.diffs = {
      ...store.state.diffs,
      mergeRequestDiff: diffsMockData[0],
      diffFiles: [file],
    };

    wrapper = shallowMountExtended(DiffFileComponent, {
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
  }

  beforeEach(() => {
    axiosMock = new MockAdapter(axios);
    createComponent();
  });

  afterEach(() => {
    axiosMock.restore();
  });

  describe('mounted', () => {
    beforeEach(() => {
      jest.spyOn(window, 'requestIdleCallback').mockImplementation((fn) => fn());
    });

    it.each`
      description                                        | fileByFile
      ${'does not prefetch if not in file-by-file mode'} | ${false}
      ${'prefetches when in file-by-file mode'}          | ${true}
    `('$description', ({ fileByFile }) => {
      createComponent({
        props: { viewDiffsFileByFile: fileByFile },
      });

      if (fileByFile) {
        expect(prefetchFileNeighborsMock).toHaveBeenCalled();
      } else {
        expect(prefetchFileNeighborsMock).not.toHaveBeenCalled();
      }
    });
  });

  describe('bus events', () => {
    beforeEach(() => {
      jest.spyOn(eventHub, '$emit').mockImplementation(() => {});
    });

    describe('during mount', () => {
      it.each`
        first    | last     | events                                                                 | file
        ${false} | ${false} | ${[]}                                                                  | ${{ inlineLines: [], parallelLines: [], expandable: true }}
        ${true}  | ${true}  | ${[]}                                                                  | ${{ inlineLines: [], parallelLines: [], expandable: true }}
        ${true}  | ${false} | ${[EVT_PERF_MARK_FIRST_DIFF_FILE_SHOWN]}                               | ${false}
        ${false} | ${true}  | ${[EVT_PERF_MARK_DIFF_FILES_END]}                                      | ${false}
        ${true}  | ${true}  | ${[EVT_PERF_MARK_FIRST_DIFF_FILE_SHOWN, EVT_PERF_MARK_DIFF_FILES_END]} | ${false}
      `(
        'emits the events $events based on the file and its position ({ first: $first, last: $last }) among all files',
        async ({ file, first, last, events }) => {
          if (file) {
            forceHasDiff({ store, ...file });
          }

          createComponent({
            file: store.state.diffs.diffFiles[0],
            first,
            last,
          });

          await nextTick();

          expect(eventHub.$emit).toHaveBeenCalledTimes(events.length);
          events.forEach((event) => {
            expect(eventHub.$emit).toHaveBeenCalledWith(event);
          });
        },
      );

      it('emits the "first file shown" and "files end" events when in File-by-File mode', async () => {
        createComponent({
          first: false,
          last: false,
          props: {
            viewDiffsFileByFile: true,
          },
        });

        await nextTick();

        expect(eventHub.$emit).toHaveBeenCalledTimes(2);
        expect(eventHub.$emit).toHaveBeenCalledWith(EVT_PERF_MARK_FIRST_DIFF_FILE_SHOWN);
        expect(eventHub.$emit).toHaveBeenCalledWith(EVT_PERF_MARK_DIFF_FILES_END);
      });
    });

    describe('after loading the diff', () => {
      it('indicates that it loaded the file', async () => {
        forceHasDiff({ store, inlineLines: [], parallelLines: [], expandable: true });
        createComponent({
          file: store.state.diffs.diffFiles[0],
          first: true,
          last: true,
        });

        jest.spyOn(wrapper.vm, 'loadCollapsedDiff').mockResolvedValue(getReadableFile());
        jest.spyOn(window, 'requestIdleCallback').mockImplementation((fn) => fn());

        makeFileAutomaticallyCollapsed(store);

        await nextTick(); // Wait for store updates to flow into the component

        toggleFile(wrapper);

        await nextTick(); // Wait for the load to resolve
        await nextTick(); // Wait for the idleCallback
        await nextTick(); // Wait for nextTick inside postRender

        expect(eventHub.$emit).toHaveBeenCalledTimes(3);
        expect(eventHub.$emit).toHaveBeenCalledWith(EVT_PERF_MARK_FIRST_DIFF_FILE_SHOWN);
        expect(eventHub.$emit).toHaveBeenCalledWith(EVT_PERF_MARK_DIFF_FILES_END);
        expect(eventHub.$emit).toHaveBeenCalledWith(EVT_DISCUSSIONS_ASSIGNED);
      });
    });

    describe('loadCollapsedDiff', () => {
      it('subscribes to loadCollapsedDiff events', () => {
        const [file] = store.state.diffs.diffFiles;
        const spyOn = jest.spyOn(notesEventHub, '$on');
        createComponent({ file });
        expect(spyOn).toHaveBeenCalledWith(
          `loadCollapsedDiff/${file.file_hash}`,
          expect.any(Function),
        );
      });

      it('resubscribes to loadCollapsedDiff events when diff file changes', async () => {
        const [file] = store.state.diffs.diffFiles;
        const newFile = getReadableFile();
        newFile.file_hash = 'foo';
        const spyOn = jest.spyOn(notesEventHub, '$on');
        const spyOff = jest.spyOn(notesEventHub, '$off');
        createComponent({ file });
        wrapper.setProps({ file: newFile });
        await nextTick();
        expect(spyOff).toHaveBeenCalledWith(
          `loadCollapsedDiff/${file.file_hash}`,
          expect.any(Function),
        );
        expect(spyOn).toHaveBeenCalledWith(
          `loadCollapsedDiff/${newFile.file_hash}`,
          expect.any(Function),
        );
      });

      it('unsubscribes to loadCollapsedDiff events when destroyed', () => {
        const [file] = store.state.diffs.diffFiles;
        const spyOff = jest.spyOn(notesEventHub, '$off');
        createComponent({ file });
        wrapper.destroy();
        expect(spyOff).toHaveBeenCalledWith(
          `loadCollapsedDiff/${file.file_hash}`,
          expect.any(Function),
        );
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

        createComponent({
          props: {
            file: store.state.diffs.diffFiles[0],
          },
        });

        expect(wrapper.vm.showLocalFileReviews).toBe(bool);
      });
    });
  });

  describe('collapsing', () => {
    describe('forced open', () => {
      it('should have content even when it is automatically collapsed', () => {
        makeFileAutomaticallyCollapsed(store);

        expect(findDiffContentArea(wrapper).element.children.length).toBe(1);
        expect(wrapper.classes('has-body')).toBe(true);
      });

      it('should have content even when it is manually collapsed', () => {
        makeFileManuallyCollapsed(store);

        expect(findDiffContentArea(wrapper).element.children.length).toBe(1);
        expect(wrapper.classes('has-body')).toBe(true);
      });
    });

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

    describe('automatically collapsed generated file', () => {
      beforeEach(() => {
        makeFileAutomaticallyCollapsed(store);
        const file = store.state.diffs.diffFiles[0];
        Object.assign(store.state.diffs.diffFiles[0], {
          ...file,
          viewer: {
            ...file.viewer,
            generated: true,
          },
        });
      });

      it('should show the generated file warning with expansion button', () => {
        const messageComponent = findDiffContentArea(wrapper).findComponent(GlSprintf);

        expect(messageComponent.attributes('message')).toBe(
          'Generated files are collapsed by default. To change this behavior, edit the %{tagStart}.gitattributes%{tagEnd} file. %{linkStart}Learn more.%{linkEnd}',
        );
        expect(findToggleButton(wrapper).exists()).toBe(true);
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
          isElementStuck.mockReturnValueOnce(true);
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
        const prepFile = async (inlineLines, parallelLines, expandable) => {
          forceHasDiff({
            store,
            inlineLines,
            parallelLines,
            expandable,
          });

          await nextTick();

          toggleFile(wrapper);
        };

        beforeEach(() => {
          jest.spyOn(wrapper.vm, 'requestDiff').mockImplementation(() => {});

          makeFileAutomaticallyCollapsed(store);
        });

        it.each`
          inlineLines | parallelLines | expandable
          ${[1]}      | ${[1]}        | ${true}
          ${[]}       | ${[1]}        | ${true}
          ${[1]}      | ${[]}         | ${true}
          ${[1]}      | ${[1]}        | ${false}
          ${[]}       | ${[]}         | ${false}
        `(
          'does not make a request to fetch the diff for a diff file like { inline: $inlineLines, parallel: $parallelLines, expandable: $expandable }',
          async ({ inlineLines, parallelLines, expandable }) => {
            await prepFile(inlineLines, parallelLines, expandable);

            expect(wrapper.vm.requestDiff).not.toHaveBeenCalled();
          },
        );

        it.each`
          inlineLines | parallelLines | expandable
          ${[]}       | ${[]}         | ${true}
        `(
          'makes a request to fetch the diff for a diff file like { inline: $inlineLines, parallel: $parallelLines, expandable: $expandable }',
          async ({ inlineLines, parallelLines, expandable }) => {
            await prepFile(inlineLines, parallelLines, expandable);

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
        createComponent({ file: getUnreadableFile() });
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

      const button = wrapper.findByTestId('blob-button');

      expect(wrapper.text()).toContain('Changes are too large to be shown.');
      expect(button.html()).toContain('View file @');
      expect(button.attributes('href')).toBe('/file/view/path');
    });
  });

  describe('merge conflicts', () => {
    it('does not render conflict alert', () => {
      const file = {
        ...getReadableFile(),
        conflict_type: null,
        renderIt: true,
      };

      createComponent({ file });

      expect(wrapper.findByTestId('conflictsAlert').exists()).toBe(false);
    });

    it('renders conflict alert when conflict_type is present', () => {
      const file = {
        ...getReadableFile(),
        conflict_type: 'both_modified',
        renderIt: true,
      };

      createComponent({ file });

      expect(wrapper.findByTestId('conflictsAlert').exists()).toBe(true);
    });
  });

  describe('file discussions', () => {
    it.each`
      extraProps                                                           | exists   | existsText
      ${{}}                                                                | ${false} | ${'does not'}
      ${{ hasCommentForm: false }}                                         | ${false} | ${'does not'}
      ${{ hasCommentForm: true }}                                          | ${true}  | ${'does'}
      ${{ discussions: [{ id: 1, position: { position_type: 'file' } }] }} | ${true}  | ${'does'}
      ${{ drafts: [{ id: 1 }] }}                                           | ${true}  | ${'does'}
    `(
      'discussions wrapper $existsText exist for file with $extraProps',
      ({ extraProps, exists }) => {
        const file = {
          ...getReadableFile(),
          ...extraProps,
        };

        createComponent({
          file,
        });

        expect(wrapper.findByTestId('file-discussions').exists()).toEqual(exists);
      },
    );

    it.each`
      hasCommentForm | exists   | existsText
      ${false}       | ${false} | ${'does not'}
      ${true}        | ${true}  | ${'does'}
    `(
      'comment form $existsText exist for hasCommentForm with $hasCommentForm',
      ({ hasCommentForm, exists }) => {
        const file = {
          ...getReadableFile(),
          hasCommentForm,
        };

        createComponent({
          file,
        });

        expect(findNoteForm(wrapper).exists()).toEqual(exists);
      },
    );

    it.each`
      discussions                                                               | exists   | existsText
      ${[]}                                                                     | ${false} | ${'does not'}
      ${[{ id: 1, position: { position_type: 'file' }, expandedOnDiff: true }]} | ${true}  | ${'does'}
    `('discussions $existsText exist for $discussions', ({ discussions, exists }) => {
      const file = {
        ...getReadableFile(),
        discussions,
      };

      createComponent({
        file,
      });

      expect(wrapper.findByTestId('diff-file-discussions').exists()).toEqual(exists);
    });

    it('hides discussions when expandedOnDiff is false', () => {
      const file = {
        ...getReadableFile(),
        discussions: [{ id: 1, position: { position_type: 'file' }, expandedOnDiff: false }],
      };

      createComponent({
        file,
      });

      expect(wrapper.findByTestId('diff-file-discussions').exists()).toEqual(false);
    });

    it('shows diff file drafts', () => {
      const file = {
        ...getReadableFile(),
        discussions: [{ id: 1, position: { position_type: 'file' }, expandedOnDiff: true }],
      };

      createComponent({
        file,
        options: {
          data: () => ({
            noteableData: {
              id: '1',
              noteable_type: 'file',
              noteableType: 'file',
              diff_head_sha: '123abc',
            },
          }),
        },
        getters: {
          notes: {
            isLoggedIn: () => true,
          },
        },
      });

      expect(wrapper.findComponent(DiffFileDrafts).exists()).toEqual(true);
      expect(wrapper.findComponent(DiffFileDrafts).props('autosaveKey')).toEqual(
        'Autosave|Note/File/1/123abc/file/',
      );
    });

    it('calls toggleFileDiscussion when toggle is emited on expansion component', () => {
      const file = {
        ...getReadableFile(),
        discussions: [
          { id: 1, position: { position_type: 'file' }, expandedOnDiff: false },
          { id: 2, position: { position_type: 'file' }, expandedOnDiff: false },
        ],
      };

      createComponent({
        file,
      });

      wrapper.findComponent(DiffFileDiscussionExpansion).vm.$emit('toggle');

      expect(toggleFileDiscussionMock).toHaveBeenCalledTimes(2);
    });

    describe('when note-form emits `handleFormUpdate`', () => {
      const file = {
        ...getReadableFile(),
        hasCommentForm: true,
      };

      const note = {};
      const parentElement = null;
      const errorCallback = jest.fn();

      beforeEach(() => {
        createComponent({
          file,
          options: { provide: { glFeatures: { commentOnFiles: true } } },
        });
      });

      it('calls saveDiffDiscussionMock', () => {
        triggerSaveNote(wrapper, note, parentElement, errorCallback);

        expect(saveDiffDiscussionMock).toHaveBeenCalledWith(expect.any(Object), {
          note,
          formData: {
            noteableData: expect.any(Object),
            diffFile: file,
            positionType: FILE_DIFF_POSITION_TYPE,
            noteableType: store.getters.noteableType,
          },
        });
      });

      describe('when saveDiffDiscussionMock throws an error', () => {
        describe.each`
          scenario                  | serverError                      | message
          ${'with server error'}    | ${{ data: { errors: 'error' } }} | ${SAVING_THE_COMMENT_FAILED}
          ${'without server error'} | ${{}}                            | ${SOMETHING_WENT_WRONG}
        `('$scenario', ({ serverError, message }) => {
          beforeEach(async () => {
            saveDiffDiscussionMock.mockRejectedValue({ response: serverError });

            triggerSaveNote(wrapper, note, parentElement, errorCallback);

            await waitForPromises();
          });

          it(`renders ${serverError ? 'server' : 'generic'} error message`, () => {
            expect(createAlert).toHaveBeenCalledWith({
              message: sprintf(message, { reason: serverError?.data?.errors }),
              parent: parentElement,
            });
          });

          it('calls errorCallback', () => {
            expect(errorCallback).toHaveBeenCalled();
          });
        });
      });
    });

    describe('when note-form emits `handleFormUpdateAddToReview`', () => {
      const file = {
        ...getReadableFile(),
        hasCommentForm: true,
      };

      const note = {};
      const parentElement = null;
      const errorCallback = jest.fn();

      beforeEach(async () => {
        createComponent({
          file,
          options: { provide: { glFeatures: { commentOnFiles: true } } },
        });

        triggerSaveDraftNote(wrapper, note, parentElement, errorCallback);

        await nextTick();
      });

      it('calls addToReview mixin', () => {
        expect(diffLineNoteFormMixin.methods.addToReview).toHaveBeenCalledWith(
          note,
          FILE_DIFF_POSITION_TYPE,
          parentElement,
          errorCallback,
        );
      });
    });
  });

  describe('comments on file', () => {
    let commentForm;
    let file;

    beforeEach(() => {
      file = {
        ...getReadableFile(),
        id: 'file_id',
        hasCommentForm: true,
      };

      createComponent({
        file,
        options: { provide: { glFeatures: { commentOnFiles: true } } },
      });

      commentForm = findNoteForm(wrapper);
    });

    it('assigns an empty string as the autosave key to the note form', () => {
      expect(commentForm.props('autosaveKey')).toBe('');
    });

    it('clears the autosave value when the note-form emits `cancelForm`', async () => {
      commentForm.vm.$emit('cancelForm');

      await nextTick();

      expect(clearDraft).toHaveBeenCalled();
    });

    describe('when the user is logged in', () => {
      beforeEach(() => {
        createComponent({
          file,
          options: {
            provide: { glFeatures: { commentOnFiles: true } },
            data: () => ({
              noteableData: {
                id: '1',
                noteable_type: 'file',
                noteableType: 'file',
                diff_head_sha: '123abc',
              },
            }),
          },
          getters: {
            notes: {
              isLoggedIn: () => true,
            },
          },
        });

        commentForm = findNoteForm(wrapper);
      });

      it('assigns the correct value as the autosave key to the note form', () => {
        expect(commentForm.props('autosaveKey')).toBe('Autosave|Note/File/1/123abc/file/file_id');
      });

      it('clears the autosaved value with the correct key', async () => {
        commentForm.vm.$emit('cancelForm');

        await nextTick();

        expect(clearDraft).toHaveBeenCalledWith('Autosave|Note/File/1/123abc/file/file_id');
      });

      it('passes autosaveKey prop to diff content', () => {
        expect(wrapper.findComponent(DiffContentComponent).props('autosaveKey')).toBe(
          'Autosave|Note/File/1/123abc/file/file_id',
        );
      });
    });
  });
});
