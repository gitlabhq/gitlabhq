import { GlDisclosureDropdownGroup } from '@gitlab/ui';
import { nextTick } from 'vue';
import EmojiPicker from '~/emoji/components/picker.vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import NoteActions from '~/wikis/wiki_notes/components/note_actions.vue';
import AbuseCategorySelector from '~/abuse_reports/components/abuse_category_selector.vue';

describe('WikiNoteActions', () => {
  let wrapper;

  const findAuthorBadge = () => wrapper.findByTestId('wiki-note-user-author-badge');
  const findAuthorBadgeText = () => findAuthorBadge().text().trim();
  const findUserAccessRoleBadge = () => wrapper.findByTestId('wiki-note-user-access-role-badge');
  const findUserAccessRoleBadgeText = () => findUserAccessRoleBadge().text().trim();
  const findDisclosureDropdownGroup = () => wrapper.findComponent(GlDisclosureDropdownGroup);
  const findReportAbuseButton = () => wrapper.findByTestId('wiki-note-report-abuse-button');
  const findEditButton = () => wrapper.findByTestId('wiki-note-edit-button');
  const findReplyButton = () => wrapper.findByTestId('wiki-note-reply-button');
  const findCopyNoteButton = () => wrapper.findByTestId('wiki-note-copy-note');
  const findDeleteButton = () => wrapper.findByTestId('wiki-note-delete-button');
  const findEmojiPicker = () => wrapper.findComponent(EmojiPicker);

  const createWrapper = (propsData, injectData) => {
    return shallowMountExtended(NoteActions, {
      provide: {
        containerName: 'test-project',
        pageAuthorEmail: 'author@example.com',
        containerType: 'project',
        ...injectData,
      },
      propsData: {
        authorId: '1',
        accessLevel: 'Maintainer',
        ...propsData,
      },
    });
  };

  describe('renders correctly', () => {
    beforeEach(() => {
      wrapper = createWrapper();
    });

    describe('author badges', () => {
      describe('when the container is a project', () => {
        it('should render access level badge', () => {
          expect(findUserAccessRoleBadgeText()).toBe('Maintainer');
          expect(findUserAccessRoleBadge().attributes('title')).toBe(
            'This user has the maintainer role in the test-project project.',
          );
        });

        it('should not render access level badge when author has no access on project', () => {
          wrapper = createWrapper({ accessLevel: null });
          expect(findUserAccessRoleBadge().exists()).toBe(false);
        });
      });

      describe('when the container is a group', () => {
        beforeEach(() => {
          wrapper = createWrapper(
            {
              accessLevel: 'Owner',
            },
            {
              containerName: 'test-group',
              containerType: 'group',
            },
          );
        });

        it('should render the access level badge', () => {
          expect(findUserAccessRoleBadgeText()).toBe('Owner');
          expect(findUserAccessRoleBadge().attributes('title')).toBe(
            'This user has the owner role in the test-group group.',
          );
        });
      });

      describe('when the comment author is also the page author', () => {
        beforeEach(() => {
          wrapper = createWrapper({
            authorEmails: ['author@example.com', 'foo@example.com'],
          });
        });

        it('should render author badge', () => {
          expect(findAuthorBadgeText()).toBe('Author');
          expect(findAuthorBadge().attributes('title')).toBe(
            'This user is the author of this page.',
          );
        });
      });

      describe('when the comment author is not also the page author', () => {
        beforeEach(() => {
          wrapper = createWrapper({
            authorEmails: ['different@example.com'],
          });
        });

        it('should not render author badge', () => {
          expect(findAuthorBadge().exists()).toBe(false);
        });
      });
    });

    describe('note actions', () => {
      it('should not render any actions by default', () => {
        expect(findEditButton().exists()).toBe(false);
        expect(findReportAbuseButton().exists()).toBe(false);
        expect(findDisclosureDropdownGroup().exists()).toBe(false);
        expect(findEmojiPicker().exists()).toBe(false);
      });

      it('should render edit button when showEdit is true', () => {
        wrapper = createWrapper({ showEdit: true });
        expect(findEditButton().exists()).toBe(true);
      });

      it('should render reply button when showReply is true', () => {
        wrapper = createWrapper({ showReply: true });
        expect(findReplyButton().exists()).toBe(true);
      });

      it('should render emoji picker when canAwardEmoji is true', () => {
        wrapper = createWrapper({ canAwardEmoji: true });
        expect(findEmojiPicker().exists()).toBe(true);
      });
    });

    describe('actions dropdown group', () => {
      it('should render the dropdown group when canReportAsAbuse is true', () => {
        wrapper = createWrapper({ canReportAsAbuse: true });
        expect(findDisclosureDropdownGroup().exists()).toBe(true);
      });

      it('should render the dropdown group when showEdit is true', () => {
        wrapper = createWrapper({ showEdit: true });
        expect(findDisclosureDropdownGroup().exists()).toBe(true);
      });

      it('should render the dropdown group when both canReportAsAbuse and showEdit are true', () => {
        wrapper = createWrapper({ canReportAsAbuse: true, showEdit: true });
        expect(findDisclosureDropdownGroup().exists()).toBe(true);
      });

      it('should not render the dropdown group when neither canReportAsAbuse nor showEdit is true', () => {
        wrapper = createWrapper({ canReportAsAbuse: false, showEdit: false });
        expect(findDisclosureDropdownGroup().exists()).toBe(false);
      });
    });

    describe('actions dropdown', () => {
      it('should not render copy link button when noteUrl is empty', () => {
        wrapper = createWrapper({ canReportAsAbuse: true });
        expect(findCopyNoteButton().exists()).toBe(false);
      });

      it('should render copy link button when noteUrl is provided', () => {
        wrapper = createWrapper({ canReportAsAbuse: true, noteUrl: 'example.com' });
        expect(findCopyNoteButton().exists()).toBe(true);
      });

      it('should not render delete button when showEdit is false', () => {
        wrapper = createWrapper({ canReportAsAbuse: true, showEdit: false });
        expect(findDeleteButton().exists()).toBe(false);
      });

      it('should render delete button when showEdit is true', () => {
        wrapper = createWrapper({ canReportAsAbuse: true, showEdit: true });
        expect(findDeleteButton().exists()).toBe(true);
      });

      it('should not render report as abuse button when canReportAsAbuse is false', () => {
        wrapper = createWrapper({ canReportAsAbuse: false, showEdit: true });
        expect(findReportAbuseButton().exists()).toBe(false);
      });

      it('should render report as abuse button when canReportAsAbuse is true', () => {
        wrapper = createWrapper({ canReportAsAbuse: true });
        expect(findReportAbuseButton().exists()).toBe(true);
      });
    });
  });

  describe('actions function correctly', () => {
    beforeEach(() => {
      wrapper = createWrapper({
        showReply: true,
        showEdit: true,
        canAwardEmoji: true,
        canReportAsAbuse: true,
      });
    });

    describe('note actions', () => {
      it('emits reply event when reply is clicked', () => {
        findReplyButton().vm.$emit('click');
        expect(Boolean(wrapper.emitted('reply'))).toBe(true);
      });

      it('emits edit event when edit is clicked', () => {
        findEditButton().vm.$emit('click');
        expect(Boolean(wrapper.emitted('edit'))).toBe(true);
      });

      it('emits award-emoji event with the correct emoji name when emoji picker emits click event', () => {
        const emojiPicker = wrapper.findComponent(EmojiPicker);
        emojiPicker.vm.$emit('click', 'test-emoji');
        expect(wrapper.emitted('award-emoji')).toEqual([['test-emoji']]);
      });
    });

    describe('actions dropdown', () => {
      const findAbuseCategorySelector = () => wrapper.findComponent(AbuseCategorySelector);

      it('emits delete event when the delete button is clicked', () => {
        findDeleteButton().vm.$emit('action');
        expect(Boolean(wrapper.emitted('delete'))).toBe(true);
      });

      it('shows report as abuse drawer when report as abuse', async () => {
        await findReportAbuseButton().vm.$emit('action');

        expect(findAbuseCategorySelector().props('showDrawer')).toEqual(true);
      });

      it('closes report as abuse drawer when it emits the close-drawer event', async () => {
        await findReportAbuseButton().vm.$emit('action');
        findAbuseCategorySelector().vm.$emit('close-drawer');

        await nextTick();
        expect(findAbuseCategorySelector().exists()).toEqual(false);
      });
    });
  });
});
