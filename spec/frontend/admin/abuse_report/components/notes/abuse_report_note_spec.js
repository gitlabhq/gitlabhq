import { shallowMount } from '@vue/test-utils';
import { GlAvatarLink, GlAvatar } from '@gitlab/ui';
import AbuseReportNote from '~/admin/abuse_report/components/notes/abuse_report_note.vue';
import NoteHeader from '~/notes/components/note_header.vue';
import EditedAt from '~/issues/show/components/edited.vue';
import AbuseReportNoteBody from '~/admin/abuse_report/components/notes/abuse_report_note_body.vue';
import AbuseReportEditNote from '~/admin/abuse_report/components/notes/abuse_report_edit_note.vue';
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

  const findEditNote = () => wrapper.findComponent(AbuseReportEditNote);
  const findEditedAt = () => wrapper.findComponent(EditedAt);

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

  describe('Editing', () => {
    it('should show edit button', () => {
      expect(findNoteActions().props()).toMatchObject({
        showEditButton: true,
      });
    });

    it('should not be in edit mode by default', () => {
      expect(findEditNote().exists()).toBe(false);
    });

    it('should trigger edit mode when `startEditing` event is emitted', async () => {
      await findNoteActions().vm.$emit('startEditing');

      expect(findEditNote().exists()).toBe(true);
      expect(findEditNote().props()).toMatchObject({
        abuseReportId: mockAbuseReportId,
        note: mockNote,
      });

      expect(findNoteHeader().exists()).toBe(false);
      expect(findNoteBody().exists()).toBe(false);
    });

    it('should hide edit mode when `cancelEditing` event is emitted', async () => {
      await findNoteActions().vm.$emit('startEditing');
      await findEditNote().vm.$emit('cancelEditing');

      expect(findEditNote().exists()).toBe(false);

      expect(findNoteHeader().exists()).toBe(true);
      expect(findNoteBody().exists()).toBe(true);
    });

    it('should update note body when `updateNote` event is emitted', async () => {
      const updatedNote = {
        ...mockNote,
        body: 'Updated body',
      };

      await findNoteActions().vm.$emit('startEditing');
      await findEditNote().vm.$emit('updateNote', updatedNote);

      expect(findNoteBody().props()).toMatchObject({
        note: updatedNote,
      });
    });
  });

  describe('Edited At', () => {
    it('should not show edited-at if lastEditedBy is null', () => {
      expect(findEditedAt().exists()).toBe(false);
    });

    it('should show edited-at if lastEditedBy is not null', () => {
      createComponent({
        note: {
          ...mockNote,
          lastEditedBy: { name: 'user', webPath: '/user' },
          lastEditedAt: '2023-10-20T02:46:50Z',
        },
      });

      expect(findEditedAt().exists()).toBe(true);

      expect(findEditedAt().props()).toMatchObject({
        updatedAt: '2023-10-20T02:46:50Z',
        updatedByName: 'user',
        updatedByPath: '/user',
      });

      expect(findEditedAt().classes()).toEqual(
        expect.arrayContaining(['gl-text-subtle', 'gl-pl-3']),
      );
    });

    it('should add the correct classList when showReplyButton is false', () => {
      createComponent({
        note: {
          ...mockNote,
          lastEditedBy: { name: 'user', webPath: '/user' },
          lastEditedAt: '2023-10-20T02:46:50Z',
        },
        showReplyButton: false,
      });

      expect(findEditedAt().classes()).toEqual(
        expect.arrayContaining(['gl-text-subtle', 'gl-pl-8']),
      );
    });
  });

  describe('Replying', () => {
    it('should show reply button', () => {
      expect(findNoteActions().props()).toMatchObject({
        showReplyButton: true,
      });
    });

    it('should bubble up `startReplying` event', () => {
      findNoteActions().vm.$emit('startReplying');

      expect(wrapper.emitted('startReplying')).toHaveLength(1);
    });
  });
});
