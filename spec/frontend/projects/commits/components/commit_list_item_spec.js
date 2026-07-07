import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { useMockInternalEventsTracking } from 'helpers/tracking_internal_events_helper';
import CommitListItem from '~/projects/commits/components/commit_list_item.vue';
import UserAvatarLink from '~/vue_shared/components/user_avatar/user_avatar_link.vue';
import UserAvatarImage from '~/vue_shared/components/user_avatar/user_avatar_image.vue';
import TimeagoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';
import CommitListItemActionButtons from '~/projects/commits/components/commit_list_item_action_buttons.vue';
import CommitListItemDescription from '~/projects/commits/components/commit_list_item_description.vue';
import CommitListItemBadges from '~/projects/commits/components/commit_list_item_badges.vue';
import { mockCommit } from './mock_data';

describe('CommitListItem', () => {
  let wrapper;

  const { bindInternalEventDocument } = useMockInternalEventsTracking();

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
  const findTimeagoTooltip = () => wrapper.findComponent(TimeagoTooltip);
  const findCommitBadges = () => wrapper.findComponent(CommitListItemBadges);
  const findActionButtons = () => wrapper.findComponent(CommitListItemActionButtons);
  const findDescription = () => wrapper.findComponent(CommitListItemDescription);
  const findOverflowMenu = () => wrapper.findByTestId('overflow-menu');
  const findCommitRow = () => wrapper.findByTestId('commit-row');

  describe('avatar rendering', () => {
    describe('when commit has author', () => {
      it('renders UserAvatarLink', () => {
        const avatarLink = findUserAvatarLink();
        expect(avatarLink.props()).toMatchObject({
          linkHref: mockCommit.author.webPath,
          imgSrc: mockCommit.author.avatarUrl,
          imgSize: 32,
          imgAlt: `${mockCommit.author.name}'s avatar`,
          lazy: true,
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
          lazy: true,
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
      expect(titleLink.text()).toBe(mockCommit.title);
    });

    it('renders truncated text with tooltip enabled', () => {
      const titleLink = findCommitTitleLink();

      expect(titleLink.classes()).toContain('@md/panel:gl-truncate');
      expect(titleLink.attributes('title')).toBe(mockCommit.title);
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

    describe('when authored date is outside the JS Date range', () => {
      const outOfRangeDate = '+292278994-08-17T07:12:55+00:00';

      beforeEach(() => {
        createComponent({ commit: { ...mockCommit, authoredDate: outOfRangeDate } });
      });

      it('does not render TimeagoTooltip', () => {
        expect(findTimeagoTooltip().exists()).toBe(false);
      });

      it('renders the raw authored date as a fallback', () => {
        expect(wrapper.findByTestId('commit-authored-date-fallback').text()).toBe(outOfRangeDate);
      });
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
  });

  describe('row click to show/hide description', () => {
    describe('when commit has description', () => {
      it('shows description when row is clicked', async () => {
        await findCommitRow().trigger('click');
        expect(findDescription().isVisible()).toBe(true);
      });

      it('hides description on second click', async () => {
        await findCommitRow().trigger('click');
        expect(findActionButtons().props('isCollapsed')).toBe(false);

        await findCommitRow().trigger('click');
        expect(findActionButtons().props('isCollapsed')).toBe(true);
      });

      it('toggles via keyboard Enter key', async () => {
        await findCommitRow().trigger('keydown.enter');
        expect(findDescription().isVisible()).toBe(true);
      });

      it('toggles via keyboard Space key', async () => {
        await findCommitRow().trigger('keydown.space');
        expect(findDescription().isVisible()).toBe(true);
      });

      it('applies cursor-pointer class', () => {
        expect(findCommitRow().classes()).toContain('gl-cursor-pointer');
      });

      it('sets tabindex="0"', () => {
        expect(findCommitRow().attributes('tabindex')).toBe('0');
      });

      it('sets aria-expanded to false initially and true after click', async () => {
        expect(findCommitRow().attributes('aria-expanded')).toBe('false');

        await findCommitRow().trigger('click');
        expect(findCommitRow().attributes('aria-expanded')).toBe('true');
      });
    });

    describe('when commit has no description', () => {
      beforeEach(() => {
        createComponent({ commit: { ...mockCommit, description: null } });
      });

      it('does not show description on click', async () => {
        await findCommitRow().trigger('click');
        expect(findActionButtons().props('isCollapsed')).toBe(true);
      });

      it('does not apply cursor-pointer class', () => {
        expect(findCommitRow().classes()).not.toContain('gl-cursor-pointer');
      });

      it('sets tabindex="-1"', () => {
        expect(findCommitRow().attributes('tabindex')).toBe('-1');
      });

      it('does not set aria-expanded', () => {
        expect(findCommitRow().attributes('aria-expanded')).toBeUndefined();
      });
    });
  });

  describe('description', () => {
    it('does not mount the description component while collapsed', () => {
      expect(findDescription().exists()).toBe(false);
    });

    it('mounts the description component once the row is expanded', async () => {
      await findActionButtons().vm.$emit('click');

      expect(findDescription().exists()).toBe(true);
    });

    it('passes commit sha to description component', async () => {
      await findActionButtons().vm.$emit('click');
      expect(findDescription().props('commitSha')).toBe(mockCommit.sha);
    });
  });

  describe('internal event tracking', () => {
    it('tracks expand event when action buttons click expands the drawer', async () => {
      const { trackEventSpy } = bindInternalEventDocument(wrapper.element);

      await findActionButtons().vm.$emit('click');

      expect(trackEventSpy).toHaveBeenCalledWith(
        'expand_collapse_commit_list_item',
        { label: 'expand' },
        undefined,
      );
    });

    it('tracks collapse event when action buttons click collapses the drawer', async () => {
      const { trackEventSpy } = bindInternalEventDocument(wrapper.element);

      await findActionButtons().vm.$emit('click');
      await findActionButtons().vm.$emit('click');

      expect(trackEventSpy).toHaveBeenLastCalledWith(
        'expand_collapse_commit_list_item',
        { label: 'collapse' },
        undefined,
      );
    });
  });
});
