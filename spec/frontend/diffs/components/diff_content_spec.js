import { GlLoadingIcon } from '@gitlab/ui';
import { createTestingPinia } from '@pinia/testing';
import { shallowMount } from '@vue/test-utils';
import Vue from 'vue';
// eslint-disable-next-line no-restricted-imports
import Vuex from 'vuex';
import { PiniaVuePlugin } from 'pinia';
import waitForPromises from 'helpers/wait_for_promises';
import { sprintf } from '~/locale';
import { createAlert } from '~/alert';
import DiffContentComponent from '~/diffs/components/diff_content.vue';
import DiffDiscussions from '~/diffs/components/diff_discussions.vue';
import DiffView from '~/diffs/components/diff_view.vue';
import DiffFileDrafts from '~/batch_comments/components/diff_file_drafts.vue';
import { IMAGE_DIFF_POSITION_TYPE } from '~/diffs/constants';
import { diffViewerModes } from '~/ide/constants';
import NoteForm from '~/notes/components/note_form.vue';
import NoPreviewViewer from '~/vue_shared/components/diff_viewer/viewers/no_preview.vue';
import NotDiffableViewer from '~/vue_shared/components/diff_viewer/viewers/not_diffable.vue';
import { SOMETHING_WENT_WRONG, SAVING_THE_COMMENT_FAILED } from '~/diffs/i18n';
import { createCustomGetters } from 'helpers/pinia_helpers';
import { globalAccessorPlugin } from '~/pinia/plugins';
import { useLegacyDiffs } from '~/diffs/stores/legacy_diffs';
import { useNotes } from '~/notes/store/legacy_notes';
import { getDiffFileMock } from '../mock_data/diff_file';

Vue.use(Vuex);
Vue.use(PiniaVuePlugin);
jest.mock('~/alert');

describe('DiffContent', () => {
  let wrapper;
  let pinia;

  const noteableTypeGetterMock = jest.fn();
  const getUserDataGetterMock = jest.fn();

  const defaultProps = {
    diffFile: getDiffFileMock(),
  };

  const createComponent = ({ props, provide } = {}) => {
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
    });

    const glFeatures = provide ? { ...provide.glFeatures } : {};

    wrapper = shallowMount(DiffContentComponent, {
      propsData: {
        ...defaultProps,
        ...props,
      },
      pinia,
      store: fakeStore,
      provide: { glFeatures },
    });
  };

  beforeEach(() => {
    pinia = createTestingPinia({
      plugins: [
        globalAccessorPlugin,
        createCustomGetters(() => ({
          legacyNotes: {},
          legacyDiffs: {},
          batchComments: {
            draftsForFile: () => () => true,
            draftsForLine: () => () => true,
            shouldRenderDraftRow: () => () => true,
            hasParallelDraftLeft: () => () => true,
            hasParallelDraftRight: () => () => true,
          },
        })),
      ],
    });
    useLegacyDiffs().projectPath = 'project/path';
    useLegacyDiffs().endpoint = 'endpoint';
    useLegacyDiffs().diffFiles = [getDiffFileMock()];
    useLegacyDiffs().saveDiffDiscussion.mockResolvedValue();
    useNotes();
  });

  describe('with text based files', () => {
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

    it('passes autosaveKey down', () => {
      const autosaveKey = 'autosave';
      createComponent({
        props: { diffFile: textDiffFile, autosaveKey },
      });

      expect(wrapper.findComponent(DiffView).props('autosaveKey')).toBe(autosaveKey);
    });
  });

  describe('with whitespace only change', () => {
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

    it('renders diff file drafts', () => {
      const autosaveKey = 'autosave';
      createComponent({
        props: {
          diffFile: {
            ...imageDiffFile,
            discussions: [
              { name: 'discussion-stub', position: { position_type: IMAGE_DIFF_POSITION_TYPE } },
            ],
          },
          autosaveKey,
        },
      });

      expect(wrapper.findComponent(DiffFileDrafts).exists()).toBe(true);
      expect(wrapper.findComponent(DiffFileDrafts).props('autosaveKey')).toBe(autosaveKey);
    });

    it('emits saveDiffDiscussion when note-form emits `handleFormUpdate`', () => {
      const noteStub = {};
      const currentDiffFile = {
        ...imageDiffFile,
        discussions: [
          { name: 'discussion-stub', position: { position_type: IMAGE_DIFF_POSITION_TYPE } },
        ],
      };
      useLegacyDiffs().commentForms = [{ fileHash: currentDiffFile.file_hash }];
      createComponent({
        props: {
          diffFile: currentDiffFile,
        },
      });

      wrapper.findComponent(NoteForm).vm.$emit('handleFormUpdate', noteStub);
      expect(useLegacyDiffs().saveDiffDiscussion).toHaveBeenCalledWith({
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
          useLegacyDiffs().saveDiffDiscussion.mockRejectedValue({ response: serverError });
          useLegacyDiffs().commentForms = [{ fileHash: imageDiffFile.file_hash }];

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
