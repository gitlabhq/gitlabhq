import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import createMockApollo from 'helpers/mock_apollo_helper';
import { createAlert } from '~/alert';
import { clearDraft } from '~/lib/utils/autosave';
import waitForPromises from 'helpers/wait_for_promises';
import createNoteMutation from '~/admin/abuse_report/graphql/notes/create_abuse_report_note.mutation.graphql';
import AbuseReportAddNote from '~/admin/abuse_report/components/notes/abuse_report_add_note.vue';
import AbuseReportCommentForm from '~/admin/abuse_report/components/notes/abuse_report_comment_form.vue';

import { mockAbuseReport, createAbuseReportNoteResponse } from '../../mock_data';

jest.mock('~/alert');
jest.mock('~/lib/utils/autosave');
Vue.use(VueApollo);

describe('Abuse Report Add Note', () => {
  let wrapper;

  const mockAbuseReportId = mockAbuseReport.report.globalId;
  const mockDiscussionId = 'gid://gitlab/Discussion/9c7228e06fb0339a3d1440fcda960acfd8baa43a';

  const mutationSuccessHandler = jest.fn().mockResolvedValue(createAbuseReportNoteResponse);

  const findTimelineEntry = () => wrapper.findByTestId('abuse-report-note-timeline-entry');
  const findTimelineEntryInner = () =>
    wrapper.findByTestId('abuse-report-note-timeline-entry-inner');
  const findCommentFormWrapper = () => wrapper.findByTestId('abuse-report-comment-form-wrapper');

  const findAbuseReportCommentForm = () => wrapper.findComponent(AbuseReportCommentForm);
  const findReplyTextarea = () => wrapper.findByTestId('abuse-report-note-reply-textarea');

  const createComponent = ({
    mutationHandler = mutationSuccessHandler,
    abuseReportId = mockAbuseReportId,
    discussionId = '',
    isNewDiscussion = true,
    showCommentForm = false,
  } = {}) => {
    wrapper = shallowMountExtended(AbuseReportAddNote, {
      apolloProvider: createMockApollo([[createNoteMutation, mutationHandler]]),
      propsData: {
        abuseReportId,
        discussionId,
        isNewDiscussion,
        showCommentForm,
      },
    });
  };

  describe('Default', () => {
    beforeEach(() => {
      createComponent();
    });

    it('should show the comment form', () => {
      expect(findAbuseReportCommentForm().exists()).toBe(true);
      expect(findAbuseReportCommentForm().props()).toMatchObject({
        abuseReportId: mockAbuseReportId,
        isSubmitting: false,
        autosaveKey: `${mockAbuseReportId}-comment`,
        commentButtonText: 'Comment',
        initialValue: '',
      });
    });

    it('should not show the reply textarea', () => {
      expect(findReplyTextarea().exists()).toBe(false);
    });

    it('should add the correct classList to timeline-entry', () => {
      expect(findTimelineEntry().classes()).toEqual(
        expect.arrayContaining(['timeline-entry', 'note-form']),
      );

      expect(findTimelineEntryInner().classes()).toEqual(['timeline-entry-inner']);
    });
  });

  describe('When the main comments has replies', () => {
    beforeEach(() => {
      createComponent({
        discussionId: 'gid://gitlab/Discussion/9c7228e06fb0339a3d1440fcda960acfd8baa43a',
        isNewDiscussion: false,
      });
    });

    it('should add the correct classLists', () => {
      expect(findTimelineEntry().classes()).toEqual(
        expect.arrayContaining([
          'note',
          'note-wrapper',
          'note-comment',
          'discussion-reply-holder',
          '!gl-border-t-0',
          'clearfix',
        ]),
      );

      expect(findTimelineEntryInner().classes()).toEqual([]);

      expect(findCommentFormWrapper().classes()).toEqual(
        expect.arrayContaining(['gl-relative', 'gl-flex', 'gl-items-start', 'gl-flex-nowrap']),
      );
    });

    it('should show not the comment form', () => {
      expect(findAbuseReportCommentForm().exists()).toBe(false);
    });

    it('should show the reply textarea', () => {
      expect(findReplyTextarea().exists()).toBe(true);
      expect(findReplyTextarea().attributes()).toMatchObject({
        rows: '1',
        placeholder: 'Reply…',
        'aria-label': 'Reply to comment',
      });
    });
  });

  describe('Adding a comment', () => {
    const noteText = 'mock note';

    beforeEach(() => {
      createComponent();

      findAbuseReportCommentForm().vm.$emit('submitForm', {
        commentText: noteText,
      });
    });

    it('should call the mutation with provided noteText', async () => {
      expect(findAbuseReportCommentForm().props('isSubmitting')).toBe(true);

      expect(mutationSuccessHandler).toHaveBeenCalledWith({
        input: {
          abuseReportId: mockAbuseReportId,
          body: noteText,
          discussionId: null,
        },
      });

      await waitForPromises();

      expect(findAbuseReportCommentForm().props('isSubmitting')).toBe(false);
    });

    it('should add the correct classList to comment-form wrapper', () => {
      expect(findCommentFormWrapper().classes()).toEqual([]);
    });

    it('should clear draft from local storage', async () => {
      await waitForPromises();

      expect(clearDraft).toHaveBeenCalledWith(`${mockAbuseReportId}-comment`);
    });

    it('should emit `cancelEditing` event', async () => {
      await waitForPromises();

      expect(wrapper.emitted('cancelEditing')).toHaveLength(1);
    });

    it.each`
      description                     | errorResponse
      ${'with an error response'}     | ${new Error('The discussion could not be found')}
      ${'without an error ressponse'} | ${null}
    `('should show an error when mutation fails $description', async ({ errorResponse }) => {
      createComponent({
        mutationHandler: jest.fn().mockRejectedValue(errorResponse),
      });

      findAbuseReportCommentForm().vm.$emit('submitForm', {
        commentText: noteText,
      });

      await waitForPromises();

      const errorMessage = errorResponse
        ? 'Comment could not be submitted: the discussion could not be found.'
        : 'Comment could not be submitted. Please check your network connection and try again.';

      expect(createAlert).toHaveBeenCalledWith({
        message: errorMessage,
        captureError: true,
        parent: expect.anything(),
      });
    });
  });

  describe('Replying to a comment', () => {
    beforeEach(() => {
      createComponent({
        discussionId: mockDiscussionId,
        isNewDiscussion: false,
        showCommentForm: false,
      });
    });

    it('should not show the comment form', () => {
      expect(findAbuseReportCommentForm().exists()).toBe(false);
    });

    it('should show comment form when reply textarea is clicked on', async () => {
      await findReplyTextarea().trigger('click');

      expect(findAbuseReportCommentForm().exists()).toBe(true);
      expect(findAbuseReportCommentForm().props('commentButtonText')).toBe('Reply');
    });

    it('should show comment form if `showCommentForm` is true', () => {
      createComponent({
        discussionId: mockDiscussionId,
        isNewDiscussion: false,
        showCommentForm: true,
      });

      expect(findAbuseReportCommentForm().exists()).toBe(true);
    });
  });
});
