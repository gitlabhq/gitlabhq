import { shallowMount } from '@vue/test-utils';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';
import CommentFieldLayout from '~/notes/components/comment_field_layout.vue';
import EmailParticipantsWarning from '~/notes/components/email_participants_warning.vue';
import NoteableWarning from '~/vue_shared/components/notes/noteable_warning.vue';

describe('Comment Field Layout Component', () => {
  let wrapper;

  const lockedDiscussionDocsPath = 'docs/locked/path';
  const confidentialIssuesDocsPath = 'docs/confidential/path';
  const noteWithAttachment =
    'Have a look at this! ![image](/uploads/aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa/image.jpg)';
  const attachmentMessage =
    'Attachments are sent by email. Attachments over 10 MB are sent as links to your GitLab instance, and only accessible to project members.';
  const confidentialAttachmentMessage =
    'Uploaded files will be accessible to anyone with the file URL. Use caution when sharing file URLs.';

  const noteableDataMock = {
    confidential: false,
    discussion_locked: false,
    locked_discussion_docs_path: lockedDiscussionDocsPath,
    confidential_issues_docs_path: confidentialIssuesDocsPath,
  };

  const findIssuableNoteWarning = () => wrapper.findComponent(NoteableWarning);
  const findEmailParticipantsWarning = () => wrapper.findComponent(EmailParticipantsWarning);
  const findErrorAlert = () => wrapper.findByTestId('comment-field-alert-container');

  const createWrapper = (props = {}) => {
    wrapper = extendedWrapper(
      shallowMount(CommentFieldLayout, {
        propsData: {
          noteableData: noteableDataMock,
          ...props,
        },
      }),
    );
  };

  describe('.error-alert', () => {
    it('does not exist by default', () => {
      createWrapper();

      expect(findErrorAlert().exists()).toBe(false);
    });

    it('exists when withAlertContainer is true', () => {
      createWrapper({ withAlertContainer: true });

      expect(findErrorAlert().isVisible()).toBe(true);
    });
  });

  describe('issue is not confidential and not locked', () => {
    it('does not show IssuableNoteWarning', () => {
      createWrapper();

      expect(findIssuableNoteWarning().exists()).toBe(false);
    });
  });

  describe('issue is confidential', () => {
    beforeEach(() => {
      createWrapper({
        noteableData: { ...noteableDataMock, confidential: true },
      });
    });

    it('shows IssuableNoteWarning', () => {
      expect(findIssuableNoteWarning().isVisible()).toBe(true);
    });

    it('sets IssuableNoteWarning props', () => {
      expect(findIssuableNoteWarning().props()).toMatchObject({
        isLocked: false,
        isConfidential: true,
        lockedNoteableDocsPath: lockedDiscussionDocsPath,
        confidentialNoteableDocsPath: confidentialIssuesDocsPath,
      });
    });
  });

  describe('issue is locked', () => {
    beforeEach(() => {
      createWrapper({
        noteableData: { ...noteableDataMock, discussion_locked: true },
      });
    });

    it('shows IssuableNoteWarning', () => {
      expect(findIssuableNoteWarning().isVisible()).toBe(true);
    });

    it('sets IssuableNoteWarning props', () => {
      expect(findIssuableNoteWarning().props()).toMatchObject({
        isConfidential: false,
        isLocked: true,
        lockedNoteableDocsPath: lockedDiscussionDocsPath,
        confidentialNoteableDocsPath: confidentialIssuesDocsPath,
      });
    });
  });

  describe('issue has no email participants', () => {
    beforeEach(() => {
      createWrapper();
    });

    it('does not show EmailParticipantsWarning', () => {
      expect(findEmailParticipantsWarning().exists()).toBe(false);
    });

    it('does not show AttachmentWarning', () => {
      expect(wrapper.text()).not.toContain(attachmentMessage);
    });
  });

  describe('issue has email participants', () => {
    beforeEach(() => {
      createWrapper({
        note: noteWithAttachment,
        noteableData: {
          ...noteableDataMock,
          issue_email_participants: [
            { email: 'someone@gitlab.com' },
            { email: 'another@gitlab.com' },
          ],
        },
      });
    });

    it('shows EmailParticipantsWarning', () => {
      expect(findEmailParticipantsWarning().exists()).toBe(true);
    });

    it('shows AttachmentsWarning', () => {
      expect(wrapper.text()).toContain(attachmentMessage);
    });

    it('sets EmailParticipantsWarning props', () => {
      expect(findEmailParticipantsWarning().props('emails')).toEqual([
        'someone@gitlab.com',
        'another@gitlab.com',
      ]);
    });
  });

  describe('issue has email participants, but note is internal', () => {
    it('does not show EmailParticipantsWarning', () => {
      createWrapper({
        noteableData: {
          ...noteableDataMock,
          issue_email_participants: [{ email: 'someone@gitlab.com' }],
        },
        isInternalNote: true,
      });

      expect(findEmailParticipantsWarning().exists()).toBe(false);
    });
  });

  describe('file attachments', () => {
    describe('when issue is confidential', () => {
      it('shows confidential attachment message', () => {
        createWrapper({
          note: noteWithAttachment,
          noteableData: {
            ...noteableDataMock,
            confidential: true,
          },
        });

        expect(wrapper.text()).toContain(confidentialAttachmentMessage);
      });
    });

    describe('when note is internal', () => {
      it('shows confidential attachment message', () => {
        createWrapper({
          note: noteWithAttachment,
          isInternalNote: true,
        });

        expect(wrapper.text()).toContain(confidentialAttachmentMessage);
      });
    });

    describe('when note is neither confidential nor internal', () => {
      it('does not show confidential attachment message', () => {
        createWrapper({
          note: noteWithAttachment,
          noteableData: {
            ...noteableDataMock,
            confidential: false,
          },
          isInternalNote: false,
        });

        expect(wrapper.text()).not.toContain(confidentialAttachmentMessage);
      });
    });
  });
});
