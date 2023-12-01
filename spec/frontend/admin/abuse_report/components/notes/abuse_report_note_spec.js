import { shallowMount } from '@vue/test-utils';
import { GlAvatarLink, GlAvatar } from '@gitlab/ui';
import AbuseReportNote from '~/admin/abuse_report/components/notes/abuse_report_note.vue';
import NoteHeader from '~/notes/components/note_header.vue';
import AbuseReportNoteBody from '~/admin/abuse_report/components/notes/abuse_report_note_body.vue';
import AbuseReportNoteActions from '~/admin/abuse_report/components/notes/abuse_report_note_actions.vue';

import { mockAbuseReport, mockDiscussionWithNoReplies } from '../../mock_data';

describe('Abuse Report Note', () => {
  let wrapper;
  const mockAbuseReportId = mockAbuseReport.report.globalId;
  const mockNote = mockDiscussionWithNoReplies[0];
  const mockShowReplyButton = true;

  const findAvatar = () => wrapper.findComponent(GlAvatar);
  const findAvatarLink = () => wrapper.findComponent(GlAvatarLink);

  const findNoteHeader = () => wrapper.findComponent(NoteHeader);
  const findNoteBody = () => wrapper.findComponent(AbuseReportNoteBody);
  const findNoteActions = () => wrapper.findComponent(AbuseReportNoteActions);

  const createComponent = ({
    note = mockNote,
    abuseReportId = mockAbuseReportId,
    showReplyButton = mockShowReplyButton,
  } = {}) => {
    wrapper = shallowMount(AbuseReportNote, {
      propsData: {
        note,
        abuseReportId,
        showReplyButton,
      },
    });
  };

  beforeEach(() => {
    createComponent();
  });

  describe('Author', () => {
    const { author } = mockNote;

    it('should show avatar', () => {
      const avatar = findAvatar();

      expect(avatar.exists()).toBe(true);
      expect(avatar.props()).toMatchObject({
        src: author.avatarUrl,
        entityName: author.username,
        alt: author.name,
      });
    });

    it('should show avatar link with popover support', () => {
      const avatarLink = findAvatarLink();

      expect(avatarLink.exists()).toBe(true);
      expect(avatarLink.classes()).toContain('js-user-link');
      expect(avatarLink.attributes()).toMatchObject({
        href: author.webUrl,
        'data-user-id': '1',
        'data-username': `${author.username}`,
      });
    });
  });

  describe('Header', () => {
    it('should show note header', () => {
      expect(findNoteHeader().exists()).toBe(true);
      expect(findNoteHeader().props()).toMatchObject({
        author: mockNote.author,
        createdAt: mockNote.createdAt,
        noteId: mockNote.id,
        noteUrl: mockNote.url,
      });
    });
  });

  describe('Body', () => {
    it('should show note body', () => {
      expect(findNoteBody().exists()).toBe(true);
      expect(findNoteBody().props()).toMatchObject({
        note: mockNote,
      });
    });
  });

  describe('Actions', () => {
    it('should show note actions', () => {
      expect(findNoteActions().exists()).toBe(true);
      expect(findNoteActions().props()).toMatchObject({
        showReplyButton: mockShowReplyButton,
      });
    });

    it('should emit `startReplying`', () => {
      findNoteActions().vm.$emit('startReplying');

      expect(wrapper.emitted('startReplying')).toHaveLength(1);
    });
  });
});
