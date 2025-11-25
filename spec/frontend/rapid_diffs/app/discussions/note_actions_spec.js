import { nextTick } from 'vue';
import {
  GlTooltipDirective,
  GlDisclosureDropdown,
  GlDisclosureDropdownItem,
  GlDisclosureDropdownGroup,
} from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import NoteActions from '~/rapid_diffs/app/discussions/note_actions.vue';
import UserAccessRoleBadge from '~/vue_shared/components/user_access_role_badge.vue';
import ReplyButton from '~/notes/components/note_actions/reply_button.vue';
import AbuseCategorySelector from '~/abuse_reports/components/abuse_category_selector.vue';
import EmojiPicker from '~/emoji/components/picker.vue';
import { isLoggedIn } from '~/lib/utils/common_utils';
import * as constants from '~/notes/constants';

jest.mock('~/lib/utils/common_utils');
// Vue 3 compat doesn't like async components
jest.mock('~/emoji/components/picker.vue', () => {
  return {
    render() {
      return null;
    },
  };
});

describe('NoteActions', () => {
  let wrapper;
  let toast;

  const defaultProps = {
    authorId: 1,
    showReply: false,
    canReportAsAbuse: false,
    isAuthor: false,
    isContributor: false,
    accessLevel: '',
    noteableType: '',
    projectName: 'Project Name',
    canEdit: false,
    canAwardEmoji: false,
    canDelete: false,
    noteUrl: '',
  };

  const findAccessRoleBadgeByText = (text) =>
    wrapper
      .findAllComponents(UserAccessRoleBadge)
      .filter((component) => component.text() === text)
      .at(0);
  const findEmojiPicker = () => wrapper.findComponent(EmojiPicker);
  const findReplyButton = () => wrapper.findComponent(ReplyButton);
  const findEditButton = () => wrapper.find('.js-note-edit');
  const findDeleteButton = () => wrapper.find('.js-note-delete');
  const findMoreActionsDropdown = () => wrapper.findComponent(GlDisclosureDropdown);
  const findReportAbuseItem = () => wrapper.find('[data-testid="report-abuse-button"]');
  const findAbuseDrawer = () => wrapper.findComponent(AbuseCategorySelector);
  const findDropdownDeleteButton = () =>
    wrapper
      .findAllComponents(GlDisclosureDropdownItem)
      .filter((item) => item.text() === 'Delete comment')
      .at(0);

  const createComponent = (props = {}) => {
    wrapper = shallowMount(NoteActions, {
      propsData: {
        ...defaultProps,
        ...props,
      },
      directives: {
        GlTooltip: GlTooltipDirective,
      },
      mocks: {
        $toast: toast,
      },
      stubs: {
        EmojiPicker,
      },
    });
  };

  beforeEach(() => {
    toast = {
      show: jest.fn(),
    };
    isLoggedIn.mockReturnValue(true);
  });

  describe('User Access Role Badges', () => {
    describe('Author Badge', () => {
      const getBadge = () => findAccessRoleBadgeByText('Author');

      it('renders the badge when isAuthor is true', () => {
        createComponent({ isAuthor: true, noteableType: constants.COMMIT_NOTEABLE_TYPE });
        const badge = getBadge();
        expect(badge.exists()).toBe(true);
        expect(badge.text()).toBe('Author');
      });

      it.each`
        noteableType                             | expectedTitle
        ${constants.COMMIT_NOTEABLE_TYPE}        | ${'Commit author'}
        ${constants.MERGE_REQUEST_NOTEABLE_TYPE} | ${'Merge request author'}
        ${'Issue'}                               | ${undefined}
      `('sets the correct tooltip title for $noteableType', ({ noteableType, expectedTitle }) => {
        createComponent({ isAuthor: true, noteableType });
        const badge = getBadge();
        expect(badge.attributes('title')).toBe(expectedTitle);
      });
    });

    describe('Member Badge', () => {
      const getBadge = () => findAccessRoleBadgeByText('Maintainer');

      it('renders the badge when accessLevel is provided', () => {
        createComponent({ accessLevel: 'Maintainer', projectName: 'GitLab' });
        const badge = getBadge();
        expect(badge.exists()).toBe(true);
        expect(badge.attributes('title')).toBe(
          'This user has the maintainer role in the GitLab project.',
        );
      });
    });

    describe('Contributor Badge', () => {
      const getBadge = () => findAccessRoleBadgeByText('Contributor');

      it('renders the badge when isContributor is true and no accessLevel is provided', () => {
        createComponent({ isContributor: true, projectName: 'GitLab' });
        const badge = getBadge();
        expect(badge.exists()).toBe(true);
        expect(badge.attributes('title')).toBe(
          'This user has previously committed to the GitLab project.',
        );
      });

      it('does not render if accessLevel is present', () => {
        createComponent({ isContributor: true, accessLevel: 'Developer' });
        expect(findAccessRoleBadgeByText('Developer').exists()).toBe(true);
        expect(
          wrapper
            .findAllComponents(UserAccessRoleBadge)
            .filter((component) => component.text() === 'Contributor'),
        ).toHaveLength(0);
      });
    });
  });

  describe('Main Actions', () => {
    it('renders the EmojiPicker when canAwardEmoji is true', () => {
      createComponent({ canAwardEmoji: true });
      expect(findEmojiPicker().exists()).toBe(true);
    });

    it('emits award event when EmojiPicker is clicked', () => {
      createComponent({ canAwardEmoji: true });
      findEmojiPicker().vm.$emit('click', 'thumbsup');
      expect(wrapper.emitted('award')).toEqual([['thumbsup']]);
    });

    it('renders the ReplyButton when showReply is true', () => {
      createComponent({ showReply: true });
      expect(findReplyButton().exists()).toBe(true);
    });

    it('emits startReplying when ReplyButton emits startReplying', () => {
      createComponent({ showReply: true });
      findReplyButton().vm.$emit('startReplying');
      expect(wrapper.emitted('startReplying')).toEqual([[]]);
    });

    it('renders the Edit button when canEdit is true', () => {
      createComponent({ canEdit: true });
      const editButton = findEditButton();
      expect(editButton.exists()).toBe(true);
      expect(editButton.attributes('icon')).toBe('pencil');
      expect(editButton.attributes('title')).toBe('Edit comment');
    });

    it('emits startEditing when the Edit button is clicked', () => {
      createComponent({ canEdit: true });
      findEditButton().vm.$emit('click');
      expect(wrapper.emitted('startEditing')).toEqual([[]]);
    });

    describe('Delete Button', () => {
      it('renders the standalone Delete button when canDelete is true and canReportAsAbuse and noteUrl are false', () => {
        createComponent({ canDelete: true, canReportAsAbuse: false, noteUrl: '' });
        const deleteButton = findDeleteButton();
        expect(deleteButton.exists()).toBe(true);
        expect(deleteButton.attributes('icon')).toBe('remove');
        expect(deleteButton.attributes('title')).toBe('Delete comment');
      });

      it('emits delete event when the standalone Delete button is clicked', () => {
        createComponent({ canDelete: true, canReportAsAbuse: false, noteUrl: '' });
        findDeleteButton().vm.$emit('click');
        expect(wrapper.emitted('delete')).toEqual([[]]);
      });

      it.each`
        canDelete | canReportAsAbuse | noteUrl  | shouldShowStandalone
        ${true}   | ${false}         | ${''}    | ${true}
        ${false}  | ${false}         | ${''}    | ${false}
        ${true}   | ${true}          | ${''}    | ${false}
        ${true}   | ${false}         | ${'url'} | ${false}
      `(
        'showDeleteAction is $shouldShowStandalone when canDelete is $canDelete, canReportAsAbuse is $canReportAsAbuse, and noteUrl is "$noteUrl"',
        ({ canDelete, canReportAsAbuse, noteUrl, shouldShowStandalone }) => {
          createComponent({ canDelete, canReportAsAbuse, noteUrl });
          expect(findDeleteButton().exists()).toBe(shouldShowStandalone);
        },
      );
    });
  });

  describe('More Actions Dropdown', () => {
    it('does not render the dropdown if not logged in and no standalone delete button', () => {
      isLoggedIn.mockReturnValue(false);
      createComponent({ canEdit: false, canReportAsAbuse: false, canDelete: false });
      expect(findMoreActionsDropdown().exists()).toBe(false);
    });

    it('renders the dropdown when standalone delete button is not shown and logged in', () => {
      createComponent({ canReportAsAbuse: true });
      expect(findMoreActionsDropdown().exists()).toBe(true);
    });

    describe('Copy Link Action', () => {
      it('shows Copy Link when noteUrl is provided', () => {
        createComponent({ noteUrl: 'http://note.url' });
        expect(findMoreActionsDropdown().text().includes('Copy link')).toBe(true);
      });

      it('hides Copy Link when noteUrl is empty', () => {
        createComponent({ noteUrl: '' });
        expect(findMoreActionsDropdown().text().includes('Copy link')).toBe(false);
      });

      it('shows toast when copy link is clicked', async () => {
        createComponent({ noteUrl: 'http://note.url' });
        const copyLinkItem = wrapper.find('.js-btn-copy-note-link');

        copyLinkItem.vm.$emit('action');
        await nextTick();

        expect(toast.show).toHaveBeenCalledWith('Link copied to clipboard.');
      });
    });

    describe('Grouped Actions', () => {
      it('renders a bordered group for reporting abuse and editing', () => {
        createComponent({ canReportAsAbuse: true, canEdit: true });
        expect(wrapper.findComponent(GlDisclosureDropdownGroup).props('bordered')).toBe(true);
      });

      it('renders Report abuse when canReportAsAbuse is true', () => {
        createComponent({ canReportAsAbuse: true });
        expect(findReportAbuseItem().exists()).toBe(true);
        expect(findReportAbuseItem().text()).toBe('Report abuse');
      });

      it('renders Delete comment dropdown item when canEdit is true', () => {
        createComponent({ canEdit: true, canReportAsAbuse: true });
        expect(findDropdownDeleteButton().exists()).toBe(true);
      });

      it('does not render Delete comment dropdown item when canEdit is false', () => {
        createComponent({ canEdit: false, canReportAsAbuse: true });
        expect(
          wrapper
            .findAllComponents(GlDisclosureDropdownItem)
            .filter((item) => item.text() === 'Delete comment'),
        ).toHaveLength(0);
      });

      it('emits delete event when the dropdown Delete comment item is clicked', () => {
        createComponent({ canEdit: true, canReportAsAbuse: true });
        findDropdownDeleteButton().vm.$emit('action');
        expect(wrapper.emitted('delete')).toEqual([[]]);
      });
    });
  });

  describe('Abuse Category Selector', () => {
    it('does not render the drawer by default', () => {
      createComponent({ canReportAsAbuse: true });
      expect(findAbuseDrawer().exists()).toBe(false);
    });

    it('opens the drawer when Report abuse is clicked', async () => {
      createComponent({ canReportAsAbuse: true, noteUrl: 'url' });
      findReportAbuseItem().vm.$emit('action');
      await nextTick();
      const abuseDrawer = findAbuseDrawer();

      expect(abuseDrawer.exists()).toBe(true);
      expect(abuseDrawer.props()).toMatchObject({
        reportedUserId: defaultProps.authorId,
        reportedFromUrl: 'url',
        showDrawer: true,
      });
    });

    it('closes the drawer when close-drawer is emitted', async () => {
      createComponent({ canReportAsAbuse: true });
      findReportAbuseItem().vm.$emit('action');

      await nextTick();

      const abuseDrawer = findAbuseDrawer();
      abuseDrawer.vm.$emit('close-drawer');
      await nextTick();

      expect(findAbuseDrawer().exists()).toBe(false);
    });
  });
});
