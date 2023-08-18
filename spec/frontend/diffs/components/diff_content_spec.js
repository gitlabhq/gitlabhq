import { GlLoadingIcon } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import Vue from 'vue';
// eslint-disable-next-line no-restricted-imports
import Vuex from 'vuex';
import waitForPromises from 'helpers/wait_for_promises';
import { sprintf } from '~/locale';
import { createAlert } from '~/alert';
import DiffContentComponent from '~/diffs/components/diff_content.vue';
import DiffDiscussions from '~/diffs/components/diff_discussions.vue';
import DiffView from '~/diffs/components/diff_view.vue';
import { IMAGE_DIFF_POSITION_TYPE } from '~/diffs/constants';
import { diffViewerModes } from '~/ide/constants';
import NoteForm from '~/notes/components/note_form.vue';
import NoPreviewViewer from '~/vue_shared/components/diff_viewer/viewers/no_preview.vue';
import NotDiffableViewer from '~/vue_shared/components/diff_viewer/viewers/not_diffable.vue';
import { SOMETHING_WENT_WRONG, SAVING_THE_COMMENT_FAILED } from '~/diffs/i18n';
import { getDiffFileMock } from '../mock_data/diff_file';

Vue.use(Vuex);
jest.mock('~/alert');

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
    diffFile: getDiffFileMock(),
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
            draftsForLine: () => () => true,
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
            diffLines: () => () => [...getDiffFileMock().parallel_diff_lines],
            fileLineCodequality: () => () => [],
            fileLineSast: () => () => [],
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
      store: fakeStore,
      provide: { glFeatures },
    });
  };

  describe('with text based files', () => {
    afterEach(() => {
      [isParallelViewGetterMock, isInlineViewGetterMock].forEach((m) => m.mockRestore());
    });

    const textDiffFile = { ...defaultProps.diffFile, viewer: { name: diffViewerModes.text } };

    it('should render diff view if `unifiedDiffComponents` are true', () => {
      createComponent({
        props: { diffFile: textDiffFile },
      });

      expect(wrapper.findComponent(DiffView).exists()).toBe(true);
    });

    it('renders rendering more lines loading icon', () => {
      createComponent({ props: { diffFile: { ...textDiffFile, renderingLines: true } } });

      expect(wrapper.findComponent(GlLoadingIcon).exists()).toBe(true);
    });
  });

  describe('with whitespace only change', () => {
    afterEach(() => {
      [isParallelViewGetterMock, isInlineViewGetterMock].forEach((m) => m.mockRestore());
    });

    const textDiffFile = {
      ...defaultProps.diffFile,
      viewer: { name: diffViewerModes.text, whitespace_only: true },
    };

    it('should render empty state', () => {
      createComponent({
        props: { diffFile: textDiffFile },
      });

      expect(wrapper.find('[data-testid="diff-whitespace-only-state"]').exists()).toBe(true);
    });

    it('emits load-file event when clicking show changes button', () => {
      createComponent({
        props: { diffFile: textDiffFile },
      });

      wrapper.find('[data-testid="diff-load-file-button"]').vm.$emit('click');

      expect(wrapper.emitted('load-file')).toEqual([[{ w: '0' }]]);
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

      expect(wrapper.findComponent(NoPreviewViewer).exists()).toBe(true);
    });

    it('should render not diffable view if viewer set to non_diffable', () => {
      createComponent({
        props: { diffFile: { ...emptyDiffFile, viewer: { name: diffViewerModes.not_diffable } } },
      });

      expect(wrapper.findComponent(NotDiffableViewer).exists()).toBe(true);
    });
  });

  describe('with image files', () => {
    const imageDiffFile = { ...defaultProps.diffFile, viewer: { name: diffViewerModes.image } };

    it('renders diff file discussions', () => {
      getCommentFormForDiffFileGetterMock.mockReturnValue(() => true);
      createComponent({
        props: {
          diffFile: {
            ...imageDiffFile,
            discussions: [
              { name: 'discussion-stub', position: { position_type: IMAGE_DIFF_POSITION_TYPE } },
            ],
          },
        },
      });

      expect(wrapper.findComponent(DiffDiscussions).exists()).toBe(true);
    });

    it('emits saveDiffDiscussion when note-form emits `handleFormUpdate`', () => {
      const noteStub = {};
      getCommentFormForDiffFileGetterMock.mockReturnValue(() => true);
      const currentDiffFile = {
        ...imageDiffFile,
        discussions: [
          { name: 'discussion-stub', position: { position_type: IMAGE_DIFF_POSITION_TYPE } },
        ],
      };
      createComponent({
        props: {
          diffFile: currentDiffFile,
        },
      });

      wrapper.findComponent(NoteForm).vm.$emit('handleFormUpdate', noteStub);
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

    describe('when note-form emits `handleFormUpdate`', () => {
      const noteStub = {};
      const parentElement = null;
      const errorCallback = jest.fn();

      describe.each`
        scenario                  | serverError                      | message
        ${'with server error'}    | ${{ data: { errors: 'error' } }} | ${SAVING_THE_COMMENT_FAILED}
        ${'without server error'} | ${null}                          | ${SOMETHING_WENT_WRONG}
      `('$scenario', ({ serverError, message }) => {
        beforeEach(async () => {
          saveDiffDiscussionMock.mockRejectedValue({ response: serverError });

          createComponent({
            props: {
              diffFile: imageDiffFile,
            },
          });

          wrapper
            .findComponent(NoteForm)
            .vm.$emit('handleFormUpdate', noteStub, parentElement, errorCallback);

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
});
