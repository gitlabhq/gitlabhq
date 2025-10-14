import { GlTruncate } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import CommitListItem from '~/projects/commits/components/commit_list_item.vue';
import UserAvatarLink from '~/vue_shared/components/user_avatar/user_avatar_link.vue';
import UserAvatarImage from '~/vue_shared/components/user_avatar/user_avatar_image.vue';
import TimeagoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';
import CommitListItemActionButtons from '~/projects/commits/components/commit_list_item_action_buttons.vue';
import CommitListItemDescription from '~/projects/commits/components/commit_list_item_description.vue';
import CommitListItemBadges from '~/projects/commits/components/commit_list_item_badges.vue';
import ExpandCollapseButton from '~/vue_shared/components/expand_collapse_button/expand_collapse_button.vue';
import { mockCommit } from './mock_data';

describe('CommitListItem', () => {
  let wrapper;

  const mockCommitWithoutAuthor = {
    ...mockCommit,
    author: null,
    authorGravatar: 'https://gravatar.com/avatar/123',
  };

  const createComponent = (props = {}) => {
    wrapper = shallowMountExtended(CommitListItem, {
      propsData: {
        commit: mockCommit,
        ...props,
      },
    });
  };

  beforeEach(() => {
    createComponent();
  });

  const findUserAvatarLink = () => wrapper.findComponent(UserAvatarLink);
  const findUserAvatarImage = () => wrapper.findComponent(UserAvatarImage);
  const findCommitTitleLink = () => wrapper.findByTestId('commit-title-link');
  const findUserPopover = () => wrapper.findByTestId('commit-user-popover');
  const findAuthorLink = () => wrapper.findByTestId('commit-author-link');
  const findTruncate = () => wrapper.findComponent(GlTruncate);

  const findTimeagoTooltip = () => wrapper.findComponent(TimeagoTooltip);
  const findCommitBadges = () => wrapper.findComponent(CommitListItemBadges);
  const findActionButtons = () => wrapper.findComponent(CommitListItemActionButtons);
  const findDescription = () => wrapper.findComponent(CommitListItemDescription);
  const findExpandCollapseButton = () => wrapper.findComponent(ExpandCollapseButton);
  const findOverflowMenu = () => wrapper.findByTestId('overflow-menu');
  const findNarrowScreenExpandCollapseContainer = () =>
    wrapper.findByTestId('narrow-screen-expand-collapse-button-container');

  describe('avatar rendering', () => {
    describe('when commit has author', () => {
      it('renders UserAvatarLink', () => {
        const avatarLink = findUserAvatarLink();
        expect(avatarLink.props()).toMatchObject({
          linkHref: mockCommit.author.webPath,
          imgSrc: mockCommit.author.avatarUrl,
          imgSize: 32,
          imgAlt: `${mockCommit.author.name}'s avatar`,
        });
      });

      it('does not render UserAvatarImage', () => {
        expect(findUserAvatarImage().exists()).toBe(false);
      });
    });

    describe('when commit has no author', () => {
      beforeEach(() => {
        createComponent({ commit: mockCommitWithoutAuthor });
      });

      it('renders UserAvatarImage', () => {
        const avatarImage = findUserAvatarImage();
        expect(avatarImage.props()).toMatchObject({
          imgSrc: mockCommitWithoutAuthor.authorGravatar,
          size: 32,
        });
      });

      it('does not render UserAvatarLink', () => {
        expect(findUserAvatarLink().exists()).toBe(false);
      });
    });
  });

  describe('commit title', () => {
    it('renders commit title as a link', () => {
      const titleLink = findCommitTitleLink();
      expect(titleLink.attributes('href')).toBe(mockCommit.webPath);
    });

    it('applies italic styling when commit has no message', () => {
      createComponent({
        commit: { ...mockCommit, message: null },
      });
      const titleLink = findCommitTitleLink();
      expect(titleLink.classes()).toContain('gl-italic');
    });

    it('renders truncated text with tooltip enabled', () => {
      const truncate = findTruncate();
      expect(truncate.props('withTooltip')).toBe(true);
      expect(truncate.props('text')).toBe(mockCommit.titleHtml);
    });
  });

  describe('author information', () => {
    describe('when commit has author', () => {
      it('renders author link with correct attributes', () => {
        const authorLink = findAuthorLink();
        expect(authorLink.attributes('href')).toBe(mockCommit.author.webPath);
        expect(authorLink.text()).toBe(mockCommit.author.name);
      });

      it('sets user popover data attributes', () => {
        const userPopover = findUserPopover();
        expect(userPopover.attributes('data-user-id')).toBe('1');
        expect(userPopover.attributes('data-username')).toBe(mockCommit.author.username);
      });
    });

    describe('when commit has no author', () => {
      beforeEach(() => {
        createComponent({ commit: mockCommitWithoutAuthor });
      });

      it('renders author name as text', () => {
        expect(wrapper.text()).toContain(mockCommitWithoutAuthor.authorName);
      });

      it('does not render author link', () => {
        expect(findAuthorLink().exists()).toBe(false);
      });
    });

    it('renders authored date with TimeagoTooltip', () => {
      const timeago = findTimeagoTooltip();
      expect(timeago.props('time')).toBe(mockCommit.authoredDate);
      expect(timeago.props('tooltipPlacement')).toBe('bottom');
    });
  });

  describe('badges', () => {
    it('renders CommitBadges component with correct props', () => {
      const commitBadges = findCommitBadges();
      expect(commitBadges.props('commit')).toBe(mockCommit);
    });
  });

  describe('action buttons', () => {
    it('renders action buttons with correct props', () => {
      const actionButtons = findActionButtons();
      expect(actionButtons.props()).toMatchObject({
        isCollapsed: true,
        commit: mockCommit,
      });
    });

    it('handles click event from action buttons', async () => {
      const actionButtons = findActionButtons();
      await actionButtons.vm.$emit('click');
      const description = findDescription();
      expect(description.isVisible()).toBe(true);
    });
  });

  describe('narrow screen only elements', () => {
    describe('overflow menu', () => {
      it('renders overflow menu with narrow screens only classes', () => {
        const overflowMenu = findOverflowMenu();
        expect(overflowMenu.classes()).toContain('@md/panel:gl-hidden');
      });
    });

    describe('expand/collapse button container', () => {
      it('renders expand/collapse button container with narrow screens only classes', () => {
        const container = findNarrowScreenExpandCollapseContainer();
        expect(container.classes()).toContain('@md/panel:gl-hidden');
      });

      it('renders expand/collapse button inside container', () => {
        const expandCollapseButton = findExpandCollapseButton();
        expect(expandCollapseButton.props()).toMatchObject({
          isCollapsed: true,
          anchorId: `commit-list-item-${mockCommit.id}`,
          size: 'medium',
        });
      });

      it('handles click event from expand/collapse button', async () => {
        const expandCollapseButton = findExpandCollapseButton();
        await expandCollapseButton.vm.$emit('click');
        const description = findDescription();
        expect(description.isVisible()).toBe(true);
      });
    });
  });
});
