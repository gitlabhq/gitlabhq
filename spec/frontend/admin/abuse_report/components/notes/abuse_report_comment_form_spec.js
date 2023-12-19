import { nextTick } from 'vue';
import { shallowMount } from '@vue/test-utils';
import waitForPromises from 'helpers/wait_for_promises';
import { ESC_KEY, ENTER_KEY } from '~/lib/utils/keys';
import * as autosave from '~/lib/utils/autosave';
import * as confirmViaGlModal from '~/lib/utils/confirm_via_gl_modal/confirm_via_gl_modal';

import AbuseReportCommentForm from '~/admin/abuse_report/components/notes/abuse_report_comment_form.vue';
import MarkdownEditor from '~/vue_shared/components/markdown/markdown_editor.vue';

import { mockAbuseReport } from '../../mock_data';

jest.mock('~/lib/utils/autosave', () => ({
  updateDraft: jest.fn(),
  clearDraft: jest.fn(),
  getDraft: jest.fn().mockReturnValue(''),
}));

jest.mock('~/lib/utils/confirm_via_gl_modal/confirm_via_gl_modal', () => ({
  confirmAction: jest.fn().mockResolvedValue(true),
}));

describe('Abuse Report Comment Form', () => {
  let wrapper;

  const mockAbuseReportId = mockAbuseReport.report.globalId;
  const mockAutosaveKey = `${mockAbuseReportId}-comment`;
  const mockInitialValue = 'note text';

  const findMarkdownEditor = () => wrapper.findComponent(MarkdownEditor);
  const findCancelButton = () => wrapper.find('[data-testid="cancel-button"]');
  const findCommentButton = () => wrapper.find('[data-testid="comment-button"]');

  const createComponent = ({
    abuseReportId = mockAbuseReportId,
    isSubmitting = false,
    initialValue = mockInitialValue,
    autosaveKey = mockAutosaveKey,
    commentButtonText = 'Comment',
  } = {}) => {
    wrapper = shallowMount(AbuseReportCommentForm, {
      propsData: {
        abuseReportId,
        isSubmitting,
        initialValue,
        autosaveKey,
        commentButtonText,
      },
      provide: {
        uploadNoteAttachmentPath: 'test-upload-path',
      },
    });
  };

  describe('Markdown editor', () => {
    it('should show markdown editor', () => {
      createComponent();

      expect(findMarkdownEditor().exists()).toBe(true);

      expect(findMarkdownEditor().props()).toMatchObject({
        value: mockInitialValue,
        renderMarkdownPath: '',
        uploadsPath: 'test-upload-path',
        enableContentEditor: false,
        formFieldProps: {
          'aria-label': 'Add a reply',
          placeholder: 'Write a comment or drag your files here…',
          id: 'abuse-report-add-or-edit-comment',
          name: 'abuse-report-add-or-edit-comment',
        },
        markdownDocsPath: '/help/user/markdown',
      });
    });

    it('should pass the draft from local storage if it exists', () => {
      jest.spyOn(autosave, 'getDraft').mockImplementation(() => 'draft comment');
      createComponent();

      expect(findMarkdownEditor().props('value')).toBe('draft comment');
    });

    it('should pass an empty string if both draft and initialValue are empty', () => {
      jest.spyOn(autosave, 'getDraft').mockImplementation(() => '');
      createComponent({ initialValue: '' });

      expect(findMarkdownEditor().props('value')).toBe('');
    });
  });

  describe('Markdown Editor input', () => {
    beforeEach(() => {
      createComponent();
    });

    it('should set the correct comment text value', async () => {
      findMarkdownEditor().vm.$emit('input', 'new comment');
      await nextTick();

      expect(findMarkdownEditor().props('value')).toBe('new comment');
    });

    it('should call `updateDraft` with correct parameters', () => {
      findMarkdownEditor().vm.$emit('input', 'new comment');

      expect(autosave.updateDraft).toHaveBeenCalledWith(mockAutosaveKey, 'new comment');
    });
  });

  describe('Submitting a comment', () => {
    beforeEach(() => {
      jest.spyOn(autosave, 'getDraft').mockImplementation(() => 'draft comment');
      createComponent();
    });

    it('should show comment button', () => {
      expect(findCommentButton().exists()).toBe(true);
      expect(findCommentButton().text()).toBe('Comment');
    });

    it('should show `Reply` button if its not a new discussion', () => {
      createComponent({ commentButtonText: 'Reply' });
      expect(findCommentButton().text()).toBe('Reply');
    });

    describe('when enter with meta key is pressed', () => {
      beforeEach(() => {
        findMarkdownEditor().vm.$emit(
          'keydown',
          new KeyboardEvent('keydown', { key: ENTER_KEY, metaKey: true }),
        );
      });

      it('should emit `submitForm` event with correct parameters', () => {
        expect(wrapper.emitted('submitForm')).toEqual([[{ commentText: 'draft comment' }]]);
      });
    });

    describe('when ctrl+enter is pressed', () => {
      beforeEach(() => {
        findMarkdownEditor().vm.$emit(
          'keydown',
          new KeyboardEvent('keydown', { key: ENTER_KEY, ctrlKey: true }),
        );
      });

      it('should emit `submitForm` event with correct parameters', () => {
        expect(wrapper.emitted('submitForm')).toEqual([[{ commentText: 'draft comment' }]]);
      });
    });

    describe('when comment button is clicked', () => {
      beforeEach(() => {
        findCommentButton().vm.$emit('click');
      });

      it('should emit `submitForm` event with correct parameters', () => {
        expect(wrapper.emitted('submitForm')).toEqual([[{ commentText: 'draft comment' }]]);
      });
    });
  });

  describe('Cancel editing', () => {
    beforeEach(() => {
      jest.spyOn(autosave, 'getDraft').mockImplementation(() => 'draft comment');
      createComponent();
    });

    it('should show cancel button', () => {
      expect(findCancelButton().exists()).toBe(true);
      expect(findCancelButton().text()).toBe('Cancel');
    });

    describe('when escape key is pressed', () => {
      beforeEach(() => {
        findMarkdownEditor().vm.$emit('keydown', new KeyboardEvent('keydown', { key: ESC_KEY }));

        return waitForPromises();
      });

      it('should confirm a user action if comment text is not empty', () => {
        expect(confirmViaGlModal.confirmAction).toHaveBeenCalled();
      });

      it('should clear draft from local storage', () => {
        expect(autosave.clearDraft).toHaveBeenCalledWith(mockAutosaveKey);
      });

      it('should emit `cancelEditing` event', () => {
        expect(wrapper.emitted('cancelEditing')).toHaveLength(1);
      });
    });

    describe('when cancel button is clicked', () => {
      beforeEach(() => {
        findCancelButton().vm.$emit('click');

        return waitForPromises();
      });

      it('should confirm a user action if comment text is not empty', () => {
        expect(confirmViaGlModal.confirmAction).toHaveBeenCalled();
      });

      it('should clear draft from local storage', () => {
        expect(autosave.clearDraft).toHaveBeenCalledWith(mockAutosaveKey);
      });

      it('should emit `cancelEditing` event', () => {
        expect(wrapper.emitted('cancelEditing')).toHaveLength(1);
      });
    });
  });
});
