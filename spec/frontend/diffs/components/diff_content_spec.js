import { GlLoadingIcon } from '@gitlab/ui';
import { shallowMount, createLocalVue } from '@vue/test-utils';
import Vuex from 'vuex';
import DiffContentComponent from '~/diffs/components/diff_content.vue';
import DiffDiscussions from '~/diffs/components/diff_discussions.vue';
import DiffView from '~/diffs/components/diff_view.vue';
import { IMAGE_DIFF_POSITION_TYPE } from '~/diffs/constants';
import { diffViewerModes } from '~/ide/constants';
import NoteForm from '~/notes/components/note_form.vue';
import NoPreviewViewer from '~/vue_shared/components/diff_viewer/viewers/no_preview.vue';
import NotDiffableViewer from '~/vue_shared/components/diff_viewer/viewers/not_diffable.vue';
import diffFileMockData from '../mock_data/diff_file';

const localVue = createLocalVue();
localVue.use(Vuex);

describe('DiffContent', () => {
  let wrapper;

  const saveDiffDiscussionMock = jest.fn();
  const closeDiffFileCommentFormMock = jest.fn();

  const noteableTypeGetterMock = jest.fn();
  const getUserDataGetterMock = jest.fn();

  const isInlineViewGetterMock = jest.fn();
  const isParallelViewGetterMock = jest.fn();
  const getCommentFormForDiffFileGetterMock = jest.fn();

  const defaultProps = {
    diffFile: JSON.parse(JSON.stringify(diffFileMockData)),
  };

  const createComponent = ({ props, state, provide } = {}) => {
    const fakeStore = new Vuex.Store({
      getters: {
        getNoteableData() {
          return {
            current_user: {
              can_create_note: true,
            },
          };
        },
        noteableType: noteableTypeGetterMock,
        getUserData: getUserDataGetterMock,
      },
      modules: {
        /*
        we need extra batchComments since vue-test-utils does not
        stub async components properly
        */
        batchComments: {
          namespaced: true,
          getters: {
            draftsForFile: () => () => true,
            draftForLine: () => () => true,
            shouldRenderDraftRow: () => () => true,
            hasParallelDraftLeft: () => () => true,
            hasParallelDraftRight: () => () => true,
          },
        },
        diffs: {
          namespaced: true,
          state: {
            projectPath: 'project/path',
            endpoint: 'endpoint',
            ...state,
          },
          getters: {
            isInlineView: isInlineViewGetterMock,
            isParallelView: isParallelViewGetterMock,
            getCommentFormForDiffFile: getCommentFormForDiffFileGetterMock,
            diffLines: () => () => [...diffFileMockData.parallel_diff_lines],
            fileLineCodequality: () => () => [],
          },
          actions: {
            saveDiffDiscussion: saveDiffDiscussionMock,
            closeDiffFileCommentForm: closeDiffFileCommentFormMock,
          },
        },
      },
    });

    const glFeatures = provide ? { ...provide.glFeatures } : {};

    wrapper = shallowMount(DiffContentComponent, {
      propsData: {
        ...defaultProps,
        ...props,
      },
      localVue,
      store: fakeStore,
      provide: { glFeatures },
    });
  };

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  describe('with text based files', () => {
    afterEach(() => {
      [isParallelViewGetterMock, isInlineViewGetterMock].forEach((m) => m.mockRestore());
    });

    const textDiffFile = { ...defaultProps.diffFile, viewer: { name: diffViewerModes.text } };

    it('should render diff view if `unifiedDiffComponents` are true', () => {
      createComponent({
        props: { diffFile: textDiffFile },
      });

      expect(wrapper.find(DiffView).exists()).toBe(true);
    });

    it('renders rendering more lines loading icon', () => {
      createComponent({ props: { diffFile: { ...textDiffFile, renderingLines: true } } });

      expect(wrapper.find(GlLoadingIcon).exists()).toBe(true);
    });
  });

  describe('with empty files', () => {
    const emptyDiffFile = {
      ...defaultProps.diffFile,
      viewer: { name: diffViewerModes.text },
      highlighted_diff_lines: [],
      parallel_diff_lines: [],
    };

    it('should render a no preview view if viewer set to no preview', () => {
      createComponent({
        props: { diffFile: { ...emptyDiffFile, viewer: { name: diffViewerModes.no_preview } } },
      });

      expect(wrapper.find(NoPreviewViewer).exists()).toBe(true);
    });

    it('should render not diffable view if viewer set to non_diffable', () => {
      createComponent({
        props: { diffFile: { ...emptyDiffFile, viewer: { name: diffViewerModes.not_diffable } } },
      });

      expect(wrapper.find(NotDiffableViewer).exists()).toBe(true);
    });
  });

  describe('with image files', () => {
    const imageDiffFile = { ...defaultProps.diffFile, viewer: { name: diffViewerModes.image } };

    it('renders diff file discussions', () => {
      getCommentFormForDiffFileGetterMock.mockReturnValue(() => true);
      createComponent({
        props: {
          diffFile: { ...imageDiffFile, discussions: [{ name: 'discussion-stub ' }] },
        },
      });

      expect(wrapper.find(DiffDiscussions).exists()).toBe(true);
    });

    it('emits saveDiffDiscussion when note-form emits `handleFormUpdate`', () => {
      const noteStub = {};
      getCommentFormForDiffFileGetterMock.mockReturnValue(() => true);
      const currentDiffFile = { ...imageDiffFile, discussions: [{ name: 'discussion-stub ' }] };
      createComponent({
        props: {
          diffFile: currentDiffFile,
        },
      });

      wrapper.find(NoteForm).vm.$emit('handleFormUpdate', noteStub);
      expect(saveDiffDiscussionMock).toHaveBeenCalledWith(expect.any(Object), {
        note: noteStub,
        formData: {
          noteableData: expect.any(Object),
          diffFile: currentDiffFile,
          positionType: IMAGE_DIFF_POSITION_TYPE,
          x: undefined,
          y: undefined,
          width: undefined,
          height: undefined,
          noteableType: undefined,
        },
      });
    });
  });
});
