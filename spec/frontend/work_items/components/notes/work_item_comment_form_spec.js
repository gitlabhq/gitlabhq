import { shallowMount } from '@vue/test-utils';
import { nextTick } from 'vue';
import waitForPromises from 'helpers/wait_for_promises';
import * as autosave from '~/lib/utils/autosave';
import { ESC_KEY, ENTER_KEY } from '~/lib/utils/keys';
import * as confirmViaGlModal from '~/lib/utils/confirm_via_gl_modal/confirm_via_gl_modal';
import WorkItemCommentForm from '~/work_items/components/notes/work_item_comment_form.vue';
import MarkdownEditor from '~/vue_shared/components/markdown/markdown_editor.vue';

const draftComment = 'draft comment';

jest.mock('~/lib/utils/autosave', () => ({
  updateDraft: jest.fn(),
  clearDraft: jest.fn(),
  getDraft: jest.fn().mockReturnValue(draftComment),
}));
jest.mock('~/lib/utils/confirm_via_gl_modal/confirm_via_gl_modal', () => ({
  confirmAction: jest.fn().mockResolvedValue(true),
}));

describe('Work item comment form component', () => {
  let wrapper;

  const mockAutosaveKey = 'test-auto-save-key';

  const findMarkdownEditor = () => wrapper.findComponent(MarkdownEditor);
  const findCancelButton = () => wrapper.find('[data-testid="cancel-button"]');
  const findConfirmButton = () => wrapper.find('[data-testid="confirm-button"]');

  const createComponent = ({ isSubmitting = false, initialValue = '' } = {}) => {
    wrapper = shallowMount(WorkItemCommentForm, {
      propsData: {
        workItemType: 'Issue',
        ariaLabel: 'test-aria-label',
        autosaveKey: mockAutosaveKey,
        isSubmitting,
        initialValue,
        markdownPreviewPath: '/group/project/preview_markdown?target_type=WorkItem',
        autocompleteDataSources: {},
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

    it('calls `updateDraft` with correct parameters', async () => {
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
});
