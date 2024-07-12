import { GlFormCheckbox, GlIcon } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import { createMockDirective } from 'helpers/vue_mock_directive';
import waitForPromises from 'helpers/wait_for_promises';
import * as autosave from '~/lib/utils/autosave';
import { ESC_KEY, ENTER_KEY } from '~/lib/utils/keys';
import { STATE_OPEN } from '~/work_items/constants';
import * as confirmViaGlModal from '~/lib/utils/confirm_via_gl_modal/confirm_via_gl_modal';
import CommentFieldLayout from '~/notes/components/comment_field_layout.vue';
import WorkItemCommentForm from '~/work_items/components/notes/work_item_comment_form.vue';
import MarkdownEditor from '~/vue_shared/components/markdown/markdown_editor.vue';
import WorkItemStateToggle from '~/work_items/components/work_item_state_toggle.vue';

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

  const findCommentFieldLayout = () => wrapper.findComponent(CommentFieldLayout);
  const findMarkdownEditor = () => wrapper.findComponent(MarkdownEditor);
  const findCancelButton = () => wrapper.find('[data-testid="cancel-button"]');
  const findConfirmButton = () => wrapper.find('[data-testid="confirm-button"]');
  const findInternalNoteCheckbox = () => wrapper.findComponent(GlFormCheckbox);
  const findInternalNoteTooltipIcon = () => wrapper.findComponent(GlIcon);
  const findWorkItemToggleStateButton = () => wrapper.findComponent(WorkItemStateToggle);

  const createComponent = ({
    isSubmitting = false,
    initialValue = '',
    isNewDiscussion = false,
    workItemState = STATE_OPEN,
    workItemType = 'Task',
    isGroup = false,
  } = {}) => {
    wrapper = shallowMount(WorkItemCommentForm, {
      provide: {
        isGroup,
      },
      propsData: {
        fullPath: 'test-project-path',
        workItemIid: '1',
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
      directives: {
        GlTooltip: createMockDirective('gl-tooltip'),
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

  it('passes correct props to CommentFieldLayout component', () => {
    createComponent();

    expect(findCommentFieldLayout().props()).toMatchObject({
      withAlertContainer: false,
      noteableData: {
        confidential: false,
        confidential_issues_docs_path: '/help/user/tasks.html#confidential-tasks',
        discussion_locked: false,
        locked_discussion_docs_path: '/help/user/tasks.html#locked-tasks',
      },
      noteableType: 'Task',
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

    expect(wrapper.emitted('submitForm')).toEqual([
      [{ commentText: draftComment, isNoteInternal: false }],
    ]);
  });

  it('emits `submitForm` event on pressing enter with meta key on markdown editor', () => {
    createComponent();
    findMarkdownEditor().vm.$emit(
      'keydown',
      new KeyboardEvent('keydown', { key: ENTER_KEY, metaKey: true }),
    );

    expect(wrapper.emitted('submitForm')).toEqual([
      [{ commentText: draftComment, isNoteInternal: false }],
    ]);
  });

  it('emits `submitForm` event on pressing ctrl+enter on markdown editor', () => {
    createComponent();
    findMarkdownEditor().vm.$emit(
      'keydown',
      new KeyboardEvent('keydown', { key: ENTER_KEY, ctrlKey: true }),
    );

    expect(wrapper.emitted('submitForm')).toEqual([
      [{ commentText: draftComment, isNoteInternal: false }],
    ]);
  });

  describe('when used as a top level/is a new discussion', () => {
    it('emits an error message when the mutation was unsuccessful', async () => {
      createComponent({
        isNewDiscussion: true,
      });
      findWorkItemToggleStateButton().vm.$emit(
        'error',
        'Something went wrong while updating the task. Please try again.',
      );

      await waitForPromises();

      expect(wrapper.emitted('error')).toEqual([
        ['Something went wrong while updating the task. Please try again.'],
      ]);
    });

    it('emits `submitForm` event on closing of work item', async () => {
      createComponent({
        isNewDiscussion: true,
      });

      findWorkItemToggleStateButton().vm.$emit('submit-comment');

      await waitForPromises();

      expect(wrapper.emitted('submitForm')).toEqual([
        [{ commentText: draftComment, isNoteInternal: false }],
      ]);
    });
  });

  describe('internal note', () => {
    it('internal note checkbox should not be visible by default', () => {
      createComponent();

      expect(findInternalNoteCheckbox().exists()).toBe(false);
    });

    describe('when used as a new discussion', () => {
      beforeEach(() => {
        createComponent({ isNewDiscussion: true });
      });

      it('should have the add as internal note capability', () => {
        expect(findInternalNoteCheckbox().exists()).toBe(true);
      });

      it('should have the tooltip explaining the internal note capabilities', () => {
        expect(findInternalNoteTooltipIcon().exists()).toBe(true);
        expect(findInternalNoteTooltipIcon().attributes('title')).toBe(
          WorkItemCommentForm.i18n.internalVisibility,
        );
      });

      it('should change the submit button text on change of value', async () => {
        findInternalNoteCheckbox().vm.$emit('input', true);
        await nextTick();

        expect(findConfirmButton().text()).toBe(WorkItemCommentForm.i18n.addInternalNote);
      });

      it('emits `submitForm` event on closing of work item', async () => {
        findInternalNoteCheckbox().vm.$emit('input', true);
        findWorkItemToggleStateButton().vm.$emit('submit-comment');

        await waitForPromises();

        expect(wrapper.emitted('submitForm')).toEqual([
          [{ commentText: draftComment, isNoteInternal: true }],
        ]);
      });
    });
  });
});
