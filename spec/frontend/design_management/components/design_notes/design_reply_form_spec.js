import { GlAlert } from '@gitlab/ui';
import { mount } from '@vue/test-utils';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import markdownEditorEventHub from '~/vue_shared/components/markdown/eventhub';
import { CLEAR_AUTOSAVE_ENTRY_EVENT } from '~/vue_shared/constants';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { confirmAction } from '~/lib/utils/confirm_via_gl_modal/confirm_via_gl_modal';
import createNoteMutation from '~/design_management/graphql/mutations/create_note.mutation.graphql';
import DesignReplyForm from '~/design_management/components/design_notes/design_reply_form.vue';
import {
  ADD_DISCUSSION_COMMENT_ERROR,
  ADD_IMAGE_DIFF_NOTE_ERROR,
  UPDATE_IMAGE_DIFF_NOTE_ERROR,
  UPDATE_NOTE_ERROR,
} from '~/design_management/utils/error_messages';
import {
  mockNoteSubmitSuccessMutationResponse,
  mockNoteSubmitFailureMutationResponse,
} from '../../mock_data/apollo_mock';

Vue.use(VueApollo);

jest.mock('~/lib/utils/confirm_via_gl_modal/confirm_via_gl_modal');
jest.mock('~/autosave');

describe('Design reply form component', () => {
  let wrapper;
  let mockApollo;

  const findTextarea = () => wrapper.find('textarea');
  const findSubmitButton = () => wrapper.findComponent({ ref: 'submitButton' });
  const findCancelButton = () => wrapper.findComponent({ ref: 'cancelButton' });
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
  const mockMutationHandler = jest.fn().mockResolvedValue(mockNoteSubmitSuccessMutationResponse);

  function createComponent({
    props = {},
    mountOptions = {},
    data = {},
    mutationHandler = mockMutationHandler,
  } = {}) {
    mockApollo = createMockApollo([[createNoteMutation, mutationHandler]]);
    wrapper = mount(DesignReplyForm, {
      propsData: {
        designNoteMutation: createNoteMutation,
        noteableId: mockNoteableId,
        markdownDocsPath: 'path/to/markdown/docs',
        markdownPreviewPath: 'path/to/markdown/preview',
        value: '',
        ...props,
      },
      ...mountOptions,
      apolloProvider: mockApollo,
      data() {
        return {
          ...data,
        };
      },
    });
  }

  beforeEach(() => {
    window.gon.current_user_id = 1;
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
    createComponent();

    expect(wrapper.text()).toContain('Switch to rich text editing');
  });

  it('renders "Attach a file or image" button in markdown toolbar', () => {
    createComponent();

    expect(wrapper.find('[data-testid="button-attach-file"]').exists()).toBe(true);
  });

  it('renders file upload progress container', () => {
    createComponent();

    expect(wrapper.find('.comment-toolbar .uploading-container').exists()).toBe(true);
  });

  it('renders button text as "Comment" when creating a comment', () => {
    createComponent();

    expect(findSubmitButton().html()).toMatchSnapshot();
  });

  it('renders button text as "Save comment" when creating a comment', () => {
    createComponent({ props: { isNewComment: false } });

    expect(findSubmitButton().html()).toMatchSnapshot();
  });

  describe('when form has no text', () => {
    beforeEach(() => {
      createComponent();
    });

    it('submit button is disabled', () => {
      expect(findSubmitButton().attributes().disabled).toBe('disabled');
    });

    it.each`
      key       | keyData
      ${'ctrl'} | ${ctrlKey}
      ${'meta'} | ${metaKey}
    `('does not perform mutation on textarea $key+enter keydown', ({ keyData }) => {
      findTextarea().trigger('keydown.enter', keyData);

      expect(mockMutationHandler).not.toHaveBeenCalled();
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

    it('calls a mutation on submit button click event', async () => {
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

      expect(mockMutationHandler).toHaveBeenCalledWith(createNoteMutationData);

      await waitForPromises();

      expect(wrapper.emitted('note-submit-complete')).toEqual([
        [mockNoteSubmitSuccessMutationResponse],
      ]);
    });

    it.each`
      key       | keyData
      ${'ctrl'} | ${ctrlKey}
      ${'meta'} | ${metaKey}
    `('does perform mutation on textarea $key+enter keydown', async ({ keyData }) => {
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

      expect(mockMutationHandler).toHaveBeenCalledWith(createNoteMutationData);

      await waitForPromises();
      expect(wrapper.emitted('note-submit-complete')).toEqual([
        [mockNoteSubmitSuccessMutationResponse],
      ]);
    });

    it('shows error message when mutation fails', async () => {
      const failedMutation = jest.fn().mockRejectedValue(mockNoteSubmitFailureMutationResponse);
      createComponent({
        props: {
          designNoteMutation: createNoteMutation,
          value: mockComment,
        },
        mutationHandler: failedMutation,
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
      createComponent();

      findTextarea().trigger('keydown.esc');

      expect(wrapper.emitted('cancel-form')).toHaveLength(1);
    });

    it('opens confirmation modal on Escape key when text has changed', () => {
      createComponent();

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
      createComponent();
      await wrapper.destroy();
      expect(clearAutosaveSpy).toHaveBeenCalled();
    });
  });
});
