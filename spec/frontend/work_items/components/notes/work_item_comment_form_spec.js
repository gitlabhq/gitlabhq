import { shallowMount } from '@vue/test-utils';
import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import waitForPromises from 'helpers/wait_for_promises';
import * as autosave from '~/lib/utils/autosave';
import { ESC_KEY, ENTER_KEY } from '~/lib/utils/keys';
import {
  STATE_OPEN,
  STATE_CLOSED,
  STATE_EVENT_REOPEN,
  STATE_EVENT_CLOSE,
} from '~/work_items/constants';
import * as confirmViaGlModal from '~/lib/utils/confirm_via_gl_modal/confirm_via_gl_modal';
import WorkItemCommentForm from '~/work_items/components/notes/work_item_comment_form.vue';
import MarkdownEditor from '~/vue_shared/components/markdown/markdown_editor.vue';
import createMockApollo from 'helpers/mock_apollo_helper';
import updateWorkItemMutation from '~/work_items/graphql/update_work_item.mutation.graphql';
import { updateWorkItemMutationResponse, workItemQueryResponse } from 'jest/work_items/mock_data';

Vue.use(VueApollo);

const draftComment = 'draft comment';

jest.mock('~/lib/utils/autosave', () => ({
  updateDraft: jest.fn(),
  clearDraft: jest.fn(),
  getDraft: jest.fn().mockReturnValue(draftComment),
}));
jest.mock('~/lib/utils/confirm_via_gl_modal/confirm_via_gl_modal', () => ({
  confirmAction: jest.fn().mockResolvedValue(true),
}));

const workItemId = 'gid://gitlab/WorkItem/1';

describe('Work item comment form component', () => {
  let wrapper;

  const mockAutosaveKey = 'test-auto-save-key';

  const findMarkdownEditor = () => wrapper.findComponent(MarkdownEditor);
  const findCancelButton = () => wrapper.find('[data-testid="cancel-button"]');
  const findConfirmButton = () => wrapper.find('[data-testid="confirm-button"]');

  const mutationSuccessHandler = jest.fn().mockResolvedValue(updateWorkItemMutationResponse);

  const createComponent = ({
    isSubmitting = false,
    initialValue = '',
    isNewDiscussion = false,
    workItemState = STATE_OPEN,
    workItemType = 'Task',
    mutationHandler = mutationSuccessHandler,
  } = {}) => {
    wrapper = shallowMount(WorkItemCommentForm, {
      apolloProvider: createMockApollo([[updateWorkItemMutation, mutationHandler]]),
      propsData: {
        workItemState,
        workItemId,
        workItemType,
        ariaLabel: 'test-aria-label',
        autosaveKey: mockAutosaveKey,
        isSubmitting,
        initialValue,
        markdownPreviewPath: '/group/project/preview_markdown?target_type=WorkItem',
        autocompleteDataSources: {},
        isNewDiscussion,
      },
      provide: {
        fullPath: 'test-project-path',
      },
    });
  };

  it('passes markdown preview path to markdown editor', () => {
    createComponent();

    expect(findMarkdownEditor().props('renderMarkdownPath')).toBe(
      '/group/project/preview_markdown?target_type=WorkItem',
    );
  });

  it('passes correct form field props to markdown editor', () => {
    createComponent();

    expect(findMarkdownEditor().props('formFieldProps')).toEqual({
      'aria-label': 'test-aria-label',
      id: 'work-item-add-or-edit-comment',
      name: 'work-item-add-or-edit-comment',
      placeholder: 'Write a comment or drag your files here…',
    });
  });

  it('passes correct `loading` prop to confirm button', () => {
    createComponent({ isSubmitting: true });

    expect(findConfirmButton().props('loading')).toBe(true);
  });

  it('passes a draft from local storage as a value to markdown editor if the draft exists', () => {
    createComponent({ initialValue: 'parent comment' });
    expect(findMarkdownEditor().props('value')).toBe(draftComment);
  });

  it('passes an initialValue prop as a value to markdown editor if storage draft does not exist', () => {
    jest.spyOn(autosave, 'getDraft').mockImplementation(() => '');
    createComponent({ initialValue: 'parent comment' });

    expect(findMarkdownEditor().props('value')).toBe('parent comment');
  });

  it('passes an empty string as a value to markdown editor if storage draft and initialValue are empty', () => {
    createComponent();

    expect(findMarkdownEditor().props('value')).toBe('');
  });

  describe('on markdown editor input', () => {
    beforeEach(() => {
      createComponent();
    });

    it('sets correct comment text value', async () => {
      expect(findMarkdownEditor().props('value')).toBe('');

      findMarkdownEditor().vm.$emit('input', 'new comment');
      await nextTick();

      expect(findMarkdownEditor().props('value')).toBe('new comment');
    });

    it('calls `updateDraft` with correct parameters', () => {
      findMarkdownEditor().vm.$emit('input', 'new comment');

      expect(autosave.updateDraft).toHaveBeenCalledWith(mockAutosaveKey, 'new comment');
    });
  });

  describe('on cancel editing', () => {
    beforeEach(() => {
      jest.spyOn(autosave, 'getDraft').mockImplementation(() => draftComment);
      createComponent();
      findMarkdownEditor().vm.$emit('keydown', new KeyboardEvent('keydown', { key: ESC_KEY }));

      return waitForPromises();
    });

    it('confirms a user action if comment text is not empty', () => {
      expect(confirmViaGlModal.confirmAction).toHaveBeenCalled();
    });

    it('emits `cancelEditing` and clears draft from the local storage', () => {
      expect(wrapper.emitted('cancelEditing')).toHaveLength(1);
      expect(autosave.clearDraft).toHaveBeenCalledWith(mockAutosaveKey);
    });
  });

  it('cancels editing on clicking cancel button', async () => {
    createComponent();
    findCancelButton().vm.$emit('click');

    await waitForPromises();

    expect(wrapper.emitted('cancelEditing')).toHaveLength(1);
    expect(autosave.clearDraft).toHaveBeenCalledWith(mockAutosaveKey);
  });

  it('emits `submitForm` event on confirm button click', () => {
    createComponent();
    findConfirmButton().vm.$emit('click');

    expect(wrapper.emitted('submitForm')).toEqual([[draftComment]]);
  });

  it('emits `submitForm` event on pressing enter with meta key on markdown editor', () => {
    createComponent();
    findMarkdownEditor().vm.$emit(
      'keydown',
      new KeyboardEvent('keydown', { key: ENTER_KEY, metaKey: true }),
    );

    expect(wrapper.emitted('submitForm')).toEqual([[draftComment]]);
  });

  it('emits `submitForm` event on pressing ctrl+enter on markdown editor', () => {
    createComponent();
    findMarkdownEditor().vm.$emit(
      'keydown',
      new KeyboardEvent('keydown', { key: ENTER_KEY, ctrlKey: true }),
    );

    expect(wrapper.emitted('submitForm')).toEqual([[draftComment]]);
  });

  describe('when used as a top level/is a new discussion', () => {
    describe('cancel button text', () => {
      it.each`
        workItemState   | workItemType    | buttonText
        ${STATE_OPEN}   | ${'Task'}       | ${'Close task'}
        ${STATE_CLOSED} | ${'Task'}       | ${'Reopen task'}
        ${STATE_OPEN}   | ${'Objective'}  | ${'Close objective'}
        ${STATE_CLOSED} | ${'Objective'}  | ${'Reopen objective'}
        ${STATE_OPEN}   | ${'Key result'} | ${'Close key result'}
        ${STATE_CLOSED} | ${'Key result'} | ${'Reopen key result'}
      `(
        'is "$buttonText" when "$workItemType" state is "$workItemState"',
        ({ workItemState, workItemType, buttonText }) => {
          createComponent({ isNewDiscussion: true, workItemState, workItemType });

          expect(findCancelButton().text()).toBe(buttonText);
        },
      );
    });

    describe('Close/reopen button click', () => {
      it.each`
        workItemState   | stateEvent
        ${STATE_OPEN}   | ${STATE_EVENT_CLOSE}
        ${STATE_CLOSED} | ${STATE_EVENT_REOPEN}
      `(
        'calls mutation with "$stateEvent" when workItemState is "$workItemState"',
        async ({ workItemState, stateEvent }) => {
          createComponent({ isNewDiscussion: true, workItemState });

          findCancelButton().vm.$emit('click');

          await waitForPromises();

          expect(mutationSuccessHandler).toHaveBeenCalledWith({
            input: {
              id: workItemQueryResponse.data.workItem.id,
              stateEvent,
            },
          });
        },
      );

      it('emits an error message when the mutation was unsuccessful', async () => {
        createComponent({
          isNewDiscussion: true,
          mutationHandler: jest.fn().mockRejectedValue('Error!'),
        });
        findCancelButton().vm.$emit('click');

        await waitForPromises();

        expect(wrapper.emitted('error')).toEqual([
          ['Something went wrong while updating the task. Please try again.'],
        ]);
      });
    });
  });
});
