import { shallowMount } from '@vue/test-utils';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';
import CommentFieldLayout from '~/notes/components/comment_field_layout.vue';
import EmailParticipantsWarning from '~/notes/components/email_participants_warning.vue';
import NoteableWarning from '~/vue_shared/components/notes/noteable_warning.vue';

describe('Comment Field Layout Component', () => {
  let wrapper;

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  const LOCKED_DISCUSSION_DOCS_PATH = 'docs/locked/path';
  const CONFIDENTIAL_ISSUES_DOCS_PATH = 'docs/confidential/path';

  const noteableDataMock = {
    confidential: false,
    discussion_locked: false,
    locked_discussion_docs_path: LOCKED_DISCUSSION_DOCS_PATH,
    confidential_issues_docs_path: CONFIDENTIAL_ISSUES_DOCS_PATH,
  };

  const findIssuableNoteWarning = () => wrapper.find(NoteableWarning);
  const findEmailParticipantsWarning = () => wrapper.find(EmailParticipantsWarning);
  const findErrorAlert = () => wrapper.findByTestId('comment-field-alert-container');

  const createWrapper = (props = {}, slots = {}) => {
    wrapper = extendedWrapper(
      shallowMount(CommentFieldLayout, {
        propsData: {
          noteableData: noteableDataMock,
          ...props,
        },
        slots,
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
        lockedNoteableDocsPath: LOCKED_DISCUSSION_DOCS_PATH,
        confidentialNoteableDocsPath: CONFIDENTIAL_ISSUES_DOCS_PATH,
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
        lockedNoteableDocsPath: LOCKED_DISCUSSION_DOCS_PATH,
        confidentialNoteableDocsPath: CONFIDENTIAL_ISSUES_DOCS_PATH,
      });
    });
  });

  describe('issue has no email participants', () => {
    it('does not show EmailParticipantsWarning', () => {
      createWrapper();

      expect(findEmailParticipantsWarning().exists()).toBe(false);
    });
  });

  describe('issue has email participants', () => {
    beforeEach(() => {
      createWrapper({
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
      expect(findEmailParticipantsWarning().isVisible()).toBe(true);
    });

    it('sets EmailParticipantsWarning props', () => {
      expect(findEmailParticipantsWarning().props('emails')).toEqual([
        'someone@gitlab.com',
        'another@gitlab.com',
      ]);
    });
  });
});
