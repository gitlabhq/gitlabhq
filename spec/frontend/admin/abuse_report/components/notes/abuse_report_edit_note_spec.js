import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import createMockApollo from 'helpers/mock_apollo_helper';
import { createAlert } from '~/alert';
import { clearDraft } from '~/lib/utils/autosave';
import waitForPromises from 'helpers/wait_for_promises';
import updateNoteMutation from '~/admin/abuse_report/graphql/notes/update_abuse_report_note.mutation.graphql';
import AbuseReportEditNote from '~/admin/abuse_report/components/notes/abuse_report_edit_note.vue';
import AbuseReportCommentForm from '~/admin/abuse_report/components/notes/abuse_report_comment_form.vue';

import {
  mockAbuseReport,
  mockDiscussionWithNoReplies,
  editAbuseReportNoteResponse,
  editAbuseReportNoteResponseWithErrors,
} from '../../mock_data';

jest.mock('~/alert');
jest.mock('~/lib/utils/autosave');
Vue.use(VueApollo);

describe('Abuse Report Edit Note', () => {
  let wrapper;

  const mockAbuseReportId = mockAbuseReport.report.globalId;
  const mockNote = mockDiscussionWithNoReplies[0];

  const mutationSuccessHandler = jest.fn().mockResolvedValue(editAbuseReportNoteResponse);
  const mutationSuccessWithErrorHandler = jest
    .fn()
    .mockResolvedValue(editAbuseReportNoteResponseWithErrors);

  const findAbuseReportCommentForm = () => wrapper.findComponent(AbuseReportCommentForm);

  const createComponent = ({
    mutationHandler = mutationSuccessHandler,
    abuseReportId = mockAbuseReportId,
    discussionId = '',
    note = mockNote,
  } = {}) => {
    wrapper = shallowMountExtended(AbuseReportEditNote, {
      apolloProvider: createMockApollo([[updateNoteMutation, mutationHandler]]),
      propsData: {
        abuseReportId,
        discussionId,
        note,
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
        autosaveKey: `${mockNote.id}-comment`,
        commentButtonText: 'Save comment',
        initialValue: mockNote.body,
      });
    });
  });

  describe('Editing a comment', () => {
    const noteText = 'Updated comment';

    beforeEach(() => {
      createComponent();

      findAbuseReportCommentForm().vm.$emit('submitForm', {
        commentText: noteText,
      });
    });

    it('should emit `cancelEditing` when editing cancelled', async () => {
      createComponent();

      findAbuseReportCommentForm().vm.$emit('cancelEditing');

      await waitForPromises();

      expect(wrapper.emitted('cancelEditing')).toHaveLength(1);
    });

    it('should call the mutation with provided noteText', async () => {
      expect(findAbuseReportCommentForm().props('isSubmitting')).toBe(true);

      expect(mutationSuccessHandler).toHaveBeenCalledWith({
        input: {
          id: mockNote.id,
          body: noteText,
        },
      });

      await waitForPromises();

      expect(findAbuseReportCommentForm().props('isSubmitting')).toBe(false);
    });

    it('should clear draft from local storage', async () => {
      await waitForPromises();

      expect(clearDraft).toHaveBeenCalledWith(`${mockNote.id}-comment`);
    });

    it('should emit `updateNote` with provided note', async () => {
      await waitForPromises();

      const { note } = editAbuseReportNoteResponse.data.updateAbuseReportNote;
      expect(wrapper.emitted('updateNote')).toStrictEqual([[note]]);
    });

    describe('handling an error response', () => {
      const bootstrap = (handler) => {
        createComponent({ mutationHandler: handler });
        findAbuseReportCommentForm().vm.$emit('submitForm', {
          commentText: noteText,
        });
      };

      it.each`
        description                     | errorResponse
        ${'with an error response'}     | ${new Error('The note could not be found')}
        ${'without an error ressponse'} | ${null}
      `('should show an error when mutation fails $description', async ({ errorResponse }) => {
        bootstrap(jest.fn().mockRejectedValue(errorResponse));

        await waitForPromises();

        const errorMessage = errorResponse
          ? 'Comment could not be updated: the note could not be found.'
          : 'Something went wrong while editing your comment. Please try again.';

        expect(createAlert).toHaveBeenCalledWith({
          message: errorMessage,
          captureError: true,
          parent: wrapper.vm.$el,
        });
      });

      it('should show correct error message when mutation is successful but contains errors', async () => {
        bootstrap(mutationSuccessWithErrorHandler);

        await waitForPromises();

        expect(createAlert).toHaveBeenCalledWith({
          message: 'Comment could not be updated: foo. bar.',
          captureError: true,
          parent: wrapper.vm.$el,
        });
      });
    });
  });
});
