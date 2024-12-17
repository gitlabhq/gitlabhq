import { GlAlert } from '@gitlab/ui';
import { mount } from '@vue/test-utils';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import markdownEditorEventHub from '~/vue_shared/components/markdown/eventhub';
import { CLEAR_AUTOSAVE_ENTRY_EVENT } from '~/vue_shared/constants';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { confirmAction } from '~/lib/utils/confirm_via_gl_modal/confirm_via_gl_modal';
import createImageDiffNoteMutation from '~/work_items/components/design_management/graphql/create_image_diff_note.mutation.graphql';
import WorkItemDesignReplyForm from '~/work_items/components/design_management/design_notes/design_reply_form.vue';
import {
  ADD_DISCUSSION_COMMENT_ERROR,
  ADD_IMAGE_DIFF_NOTE_ERROR,
  UPDATE_IMAGE_DIFF_NOTE_ERROR,
  UPDATE_NOTE_ERROR,
} from '~/work_items/components/design_management/constants';
import {
  mockNoteSubmitSuccessMutationResponse,
  mockNoteSubmitFailureMutationResponse,
} from './mock_data';

Vue.use(VueApollo);

jest.mock('~/lib/utils/confirm_via_gl_modal/confirm_via_gl_modal');
jest.mock('~/autosave');

describe('Design reply form component', () => {
  let wrapper;
  let mockApollo;

  const findTextarea = () => wrapper.find('textarea');
  const findSubmitButton = () => wrapper.findComponent({ ref: 'submitButton' });
  const findCancelButton = () => wrapper.findComponent({ ref: 'cancelButton' });
  const findAttachButton = () => wrapper.find('[data-testid="button-attach-file"]');
  const findFileUploadContainer = () => wrapper.find('.comment-toolbar .uploading-container');
  const findAlert = () => wrapper.findComponent(GlAlert);

  const mockNoteableId = 'gid://gitlab/DesignManagement::Design/6';
  const mockComment = 'New comment';
  const mockDiscussionId = 'gid://gitlab/Discussion/6466a72f35b163f3c3e52d7976a09387f2c573e8';
  const createNoteMutationData = {
    input: {
      noteableId: mockNoteableId,
      discussionId: mockDiscussionId,
      body: mockComment,
    },
  };

  const ctrlKey = {
    ctrlKey: true,
  };
  const metaKey = {
    metaKey: true,
  };
  const createImageNoteMutationSuccessHandler = jest
    .fn()
    .mockResolvedValue(mockNoteSubmitSuccessMutationResponse);
  const createImageNoteMutationError = jest
    .fn()
    .mockRejectedValue(mockNoteSubmitFailureMutationResponse);

  function createComponent({
    props = {},
    mountOptions = {},
    data = {},
    createImageNoteMutationHandler = createImageNoteMutationSuccessHandler,
  } = {}) {
    mockApollo = createMockApollo([[createImageDiffNoteMutation, createImageNoteMutationHandler]]);
    wrapper = mount(WorkItemDesignReplyForm, {
      apolloProvider: mockApollo,
      propsData: {
        designNoteMutation: createImageDiffNoteMutation,
        noteableId: mockNoteableId,
        markdownDocsPath: 'path/to/markdown/docs',
        markdownPreviewPath: 'path/to/markdown/preview',
        value: '',
        ...props,
      },
      ...mountOptions,
      data() {
        return {
          ...data,
        };
      },
      provide: {
        fullPath: 'gitlab-org/gitlab-shell',
      },
    });
  }

  beforeEach(() => {
    window.gon.current_user_id = 1;
    createComponent();
  });

  afterEach(() => {
    mockApollo = null;
    confirmAction.mockReset();
  });

  it('textarea has focus after component mount', () => {
    // We need to attach to document, so that `document.activeElement` is properly set in jsdom
    createComponent({ mountOptions: { attachTo: document.body } });

    expect(findTextarea().element).toEqual(document.activeElement);
  });

  it('allows switching to rich text', () => {
    expect(wrapper.text()).toContain('Switch to rich text editing');
  });

  it('renders "Attach a file or image" button and upload congtainer in markdown toolbar', () => {
    expect(findAttachButton().exists()).toBe(true);
    expect(findFileUploadContainer().exists()).toBe(true);
  });

  it('renders button text as "Comment" when creating a comment', () => {
    expect(findSubmitButton().html()).toMatchSnapshot();
  });

  it('renders button text as "Save comment" when creating a comment', () => {
    createComponent({ props: { isNewComment: false } });

    expect(findSubmitButton().html()).toMatchSnapshot();
  });

  describe('when form has no text', () => {
    it('submit button is disabled', () => {
      expect(findSubmitButton().attributes().disabled).toBe('disabled');
    });

    it.each`
      key       | keyData
      ${'ctrl'} | ${ctrlKey}
      ${'meta'} | ${metaKey}
    `('does not perform mutation on textarea $key+enter keydown', ({ keyData }) => {
      findTextarea().trigger('keydown.enter', keyData);

      expect(createImageNoteMutationSuccessHandler).not.toHaveBeenCalled();
    });

    it('emits cancelForm event on pressing escape button on textarea', () => {
      findTextarea().trigger('keydown.esc');

      expect(wrapper.emitted('cancel-form')).toHaveLength(1);
    });

    it('emits cancelForm event on clicking Cancel button', () => {
      findCancelButton().vm.$emit('click');

      expect(wrapper.emitted('cancel-form')).toHaveLength(1);
    });
  });

  describe('when the form has text', () => {
    it('submit button is enabled', () => {
      createComponent({ props: { value: mockComment } });
      expect(findSubmitButton().attributes().disabled).toBeUndefined();
    });

    it('calls a mutation on submit button click event', () => {
      const mockMutationVariables = {
        noteableId: mockNoteableId,
        discussionId: mockDiscussionId,
      };

      createComponent({
        props: {
          mutationVariables: mockMutationVariables,
          value: mockComment,
        },
      });

      findSubmitButton().vm.$emit('click');

      expect(createImageNoteMutationSuccessHandler).toHaveBeenCalledWith(createNoteMutationData);
    });

    it.each`
      key       | keyData
      ${'ctrl'} | ${ctrlKey}
      ${'meta'} | ${metaKey}
    `('triggers mutation on textarea $key+enter keydown', ({ keyData }) => {
      const mockMutationVariables = {
        noteableId: mockNoteableId,
        discussionId: mockDiscussionId,
      };

      createComponent({
        props: {
          mutationVariables: mockMutationVariables,
          value: mockComment,
        },
      });

      findTextarea().trigger('keydown.enter', keyData);

      expect(createImageNoteMutationSuccessHandler).toHaveBeenCalledWith(createNoteMutationData);
    });

    it('shows error message when mutation fails', async () => {
      createComponent({
        props: {
          designNoteMutation: createImageDiffNoteMutation,
          value: mockComment,
        },
        createImageNoteMutationHandler: createImageNoteMutationError,
        data: {
          errorMessage: 'error',
        },
      });

      findSubmitButton().vm.$emit('click');

      await waitForPromises();
      expect(findAlert().exists()).toBe(true);
    });

    it.each`
      isDiscussion | isNewComment | errorMessage
      ${true}      | ${true}      | ${ADD_IMAGE_DIFF_NOTE_ERROR}
      ${true}      | ${false}     | ${UPDATE_IMAGE_DIFF_NOTE_ERROR}
      ${false}     | ${true}      | ${ADD_DISCUSSION_COMMENT_ERROR}
      ${false}     | ${false}     | ${UPDATE_NOTE_ERROR}
    `(
      'return proper error message on error in case of isDiscussion is $isDiscussion and isNewComment is $isNewComment',
      ({ isDiscussion, isNewComment, errorMessage }) => {
        createComponent({ props: { isDiscussion, isNewComment } });

        expect(wrapper.vm.getErrorMessage()).toBe(errorMessage);
      },
    );

    it('emits cancelForm event on Escape key if text was not changed', () => {
      findTextarea().trigger('keydown.esc');

      expect(wrapper.emitted('cancel-form')).toHaveLength(1);
    });

    it('opens confirmation modal on Escape key when text has changed', () => {
      findTextarea().setValue(mockComment);

      findTextarea().trigger('keydown.esc');

      expect(confirmAction).toHaveBeenCalled();
    });

    it('emits cancelForm event when confirmed', async () => {
      confirmAction.mockResolvedValueOnce(true);

      createComponent({ props: { value: mockComment } });
      findTextarea().setValue('Comment changed');

      findTextarea().trigger('keydown.esc');

      expect(confirmAction).toHaveBeenCalled();

      await waitForPromises();
      expect(wrapper.emitted('cancel-form')).toHaveLength(1);
    });

    it('does not emit cancelForm event when not confirmed', async () => {
      confirmAction.mockResolvedValueOnce(false);

      createComponent({ props: { value: mockComment } });
      findTextarea().setValue('Comment changed');

      findTextarea().trigger('keydown.esc');

      expect(confirmAction).toHaveBeenCalled();
      await waitForPromises();

      expect(wrapper.emitted('cancel-form')).toBeUndefined();
    });
  });

  describe('when component is destroyed', () => {
    it('clears autosave entry', async () => {
      const clearAutosaveSpy = jest.fn();
      markdownEditorEventHub.$on(CLEAR_AUTOSAVE_ENTRY_EVENT, clearAutosaveSpy);

      await wrapper.destroy();
      expect(clearAutosaveSpy).toHaveBeenCalled();
    });
  });
});
