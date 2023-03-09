import { mount } from '@vue/test-utils';
import { nextTick } from 'vue';
import Autosave from '~/autosave';
import waitForPromises from 'helpers/wait_for_promises';
import { confirmAction } from '~/lib/utils/confirm_via_gl_modal/confirm_via_gl_modal';
import createNoteMutation from '~/design_management/graphql/mutations/create_note.mutation.graphql';
import DesignReplyForm from '~/design_management/components/design_notes/design_reply_form.vue';
import {
  mockNoteSubmitSuccessMutationResponse,
  mockNoteSubmitFailureMutationResponse,
} from '../../mock_data/apollo_mock';

jest.mock('~/lib/utils/confirm_via_gl_modal/confirm_via_gl_modal');
jest.mock('~/autosave');

describe('Design reply form component', () => {
  let wrapper;
  let originalGon;

  const findTextarea = () => wrapper.find('textarea');
  const findSubmitButton = () => wrapper.findComponent({ ref: 'submitButton' });
  const findCancelButton = () => wrapper.findComponent({ ref: 'cancelButton' });

  const mockNoteableId = 'gid://gitlab/DesignManagement::Design/6';
  const mockComment = 'New comment';
  const mockDiscussionId = 'gid://gitlab/Discussion/6466a72f35b163f3c3e52d7976a09387f2c573e8';
  const createNoteMutationData = {
    mutation: createNoteMutation,
    update: expect.anything(),
    variables: {
      input: {
        noteableId: mockNoteableId,
        discussionId: mockDiscussionId,
        body: mockComment,
      },
    },
  };

  const ctrlKey = {
    ctrlKey: true,
  };
  const metaKey = {
    metaKey: true,
  };
  const mutationHandler = jest.fn().mockResolvedValue();

  function createComponent({ props = {}, mountOptions = {}, mutation = mutationHandler } = {}) {
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
      mocks: {
        $apollo: {
          mutate: mutation,
        },
      },
    });
  }

  beforeEach(() => {
    originalGon = window.gon;
    window.gon.current_user_id = 1;
  });

  afterEach(() => {
    window.gon = originalGon;
    confirmAction.mockReset();
  });

  it('textarea has focus after component mount', () => {
    // We need to attach to document, so that `document.activeElement` is properly set in jsdom
    createComponent({ mountOptions: { attachTo: document.body } });

    expect(findTextarea().element).toEqual(document.activeElement);
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

  it.each`
    discussionId                         | shortDiscussionId
    ${undefined}                         | ${'new'}
    ${'gid://gitlab/DiffDiscussion/123'} | ${123}
  `(
    'initializes autosave support on discussion with proper key',
    async ({ discussionId, shortDiscussionId }) => {
      createComponent({ props: { discussionId } });
      await nextTick();

      expect(Autosave).toHaveBeenCalledWith(expect.any(Element), [
        'Discussion',
        6,
        shortDiscussionId,
      ]);
    },
  );

  describe('when form has no text', () => {
    beforeEach(async () => {
      createComponent();
      await nextTick();
    });

    it('submit button is disabled', () => {
      expect(findSubmitButton().attributes().disabled).toBe('disabled');
    });

    it.each`
      key       | keyData
      ${'ctrl'} | ${ctrlKey}
      ${'meta'} | ${metaKey}
    `('does not perform mutation on textarea $key+enter keydown', async ({ keyData }) => {
      findTextarea().trigger('keydown.enter', keyData);

      await nextTick();
      expect(mutationHandler).not.toHaveBeenCalled();
    });

    it('emits cancelForm event on pressing escape button on textarea', () => {
      findTextarea().trigger('keyup.esc');

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
      const successfulMutation = jest.fn().mockResolvedValue(mockNoteSubmitSuccessMutationResponse);
      createComponent({
        props: {
          designNoteMutation: createNoteMutation,
          mutationVariables: mockMutationVariables,
          value: mockComment,
        },
        mutation: successfulMutation,
      });

      findSubmitButton().vm.$emit('click');

      await nextTick();
      expect(successfulMutation).toHaveBeenCalledWith(createNoteMutationData);

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
      const successfulMutation = jest.fn().mockResolvedValue(mockNoteSubmitSuccessMutationResponse);
      createComponent({
        props: {
          designNoteMutation: createNoteMutation,
          mutationVariables: mockMutationVariables,
          value: mockComment,
        },
        mutation: successfulMutation,
      });

      findTextarea().trigger('keydown.enter', keyData);

      await nextTick();
      expect(successfulMutation).toHaveBeenCalledWith(createNoteMutationData);

      await waitForPromises();
      expect(wrapper.emitted('note-submit-complete')).toEqual([
        [mockNoteSubmitSuccessMutationResponse],
      ]);
    });

    it('emits error when mutation fails', async () => {
      const mockMutationVariables = {
        noteableId: mockNoteableId,
        discussionId: mockDiscussionId,
      };
      const failedMutation = jest.fn().mockRejectedValue(mockNoteSubmitFailureMutationResponse);
      createComponent({
        props: {
          designNoteMutation: createNoteMutation,
          mutationVariables: mockMutationVariables,
          value: mockComment,
        },
        mutation: failedMutation,
      });

      findSubmitButton().vm.$emit('click');

      await waitForPromises();
      expect(wrapper.emitted('note-submit-failure')).toEqual([
        [mockNoteSubmitFailureMutationResponse],
      ]);
    });

    it('emits cancelForm event on Escape key if text was not changed', () => {
      createComponent();

      findTextarea().trigger('keyup.esc');

      expect(wrapper.emitted('cancel-form')).toHaveLength(1);
    });

    it('opens confirmation modal on Escape key when text has changed', async () => {
      createComponent();

      findTextarea().setValue(mockComment);

      await nextTick();
      findTextarea().trigger('keyup.esc');

      expect(confirmAction).toHaveBeenCalled();
    });

    it('emits cancelForm event when confirmed', async () => {
      confirmAction.mockResolvedValueOnce(true);

      createComponent({ props: { value: mockComment } });
      findTextarea().setValue('Comment changed');

      await nextTick();
      findTextarea().trigger('keyup.esc');

      expect(confirmAction).toHaveBeenCalled();

      await waitForPromises();
      expect(wrapper.emitted('cancel-form')).toHaveLength(1);
    });

    it('does not emit cancelForm event when not confirmed', async () => {
      confirmAction.mockResolvedValueOnce(false);

      createComponent({ props: { value: mockComment } });
      findTextarea().setValue('Comment changed');
      await nextTick();

      findTextarea().trigger('keyup.esc');
      await nextTick();

      expect(confirmAction).toHaveBeenCalled();
      await waitForPromises();

      expect(wrapper.emitted('cancel-form')).toBeUndefined();
    });
  });

  describe('when component is destroyed', () => {
    it('calls autosave.reset', async () => {
      const autosaveResetSpy = jest.spyOn(Autosave.prototype, 'reset');
      createComponent();
      await wrapper.destroy();
      expect(autosaveResetSpy).toHaveBeenCalled();
    });
  });
});
