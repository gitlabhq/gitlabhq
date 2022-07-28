import { GlSkeletonLoader, GlIcon } from '@gitlab/ui';
import { loadHTMLFixture, resetHTMLFixture } from 'helpers/fixtures';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import { AVAILABILITY_STATUS } from '~/set_status_modal/utils';
import UserPopover from '~/vue_shared/components/user_popover/user_popover.vue';
import axios from '~/lib/utils/axios_utils';
import createFlash from '~/flash';
import { followUser, unfollowUser } from '~/api/user_api';
import { mockTracking } from 'helpers/tracking_helper';

jest.mock('~/flash');
jest.mock('~/api/user_api', () => ({
  followUser: jest.fn(),
  unfollowUser: jest.fn(),
}));

const DEFAULT_PROPS = {
  user: {
    id: 1,
    username: 'root',
    name: 'Administrator',
    location: 'Vienna',
    localTime: '2:30 PM',
    bot: false,
    bio: null,
    workInformation: null,
    status: null,
    pronouns: 'they/them',
    isFollowed: false,
    loaded: true,
  },
};

describe('User Popover Component', () => {
  const fixtureTemplate = 'merge_requests/diff_comment.html';

  let wrapper;

  beforeEach(() => {
    loadHTMLFixture(fixtureTemplate);
    gon.features = {};
  });

  afterEach(() => {
    wrapper.destroy();
    resetHTMLFixture();
  });

  const findUserStatus = () => wrapper.findByTestId('user-popover-status');
  const findTarget = () => document.querySelector('.js-user-link');
  const findSecurityBotDocsLink = () => wrapper.findByTestId('user-popover-bot-docs-link');
  const findUserLocalTime = () => wrapper.findByTestId('user-popover-local-time');
  const findToggleFollowButton = () => wrapper.findByTestId('toggle-follow-button');

  const itTracksToggleFollowButtonClick = (expectedLabel) => {
    it('tracks click', async () => {
      const trackingSpy = mockTracking(undefined, wrapper.element, jest.spyOn);

      await findToggleFollowButton().trigger('click');

      expect(trackingSpy).toHaveBeenCalledWith(undefined, 'click_button', {
        label: expectedLabel,
      });
    });
  };

  const createWrapper = (props = {}) => {
    wrapper = mountExtended(UserPopover, {
      propsData: {
        ...DEFAULT_PROPS,
        target: findTarget(),
        ...props,
      },
    });
  };

  describe('when user is loading', () => {
    it('displays skeleton loader', () => {
      createWrapper({
        user: {
          name: null,
          username: null,
          location: null,
          bio: null,
          workInformation: null,
          status: null,
          loaded: false,
        },
      });

      expect(wrapper.findComponent(GlSkeletonLoader).exists()).toBe(true);
    });
  });

  describe('basic data', () => {
    it('should show basic fields', () => {
      createWrapper();

      expect(wrapper.text()).toContain(DEFAULT_PROPS.user.name);
      expect(wrapper.text()).toContain(DEFAULT_PROPS.user.username);
    });

    it('shows icon for location', () => {
      createWrapper();
      const iconEl = wrapper.findComponent(GlIcon);

      expect(iconEl.props('name')).toEqual('location');
    });

    it("should not show a link to bot's documentation", () => {
      createWrapper();
      const securityBotDocsLink = findSecurityBotDocsLink();
      expect(securityBotDocsLink.exists()).toBe(false);
    });
  });

  describe('job data', () => {
    const findWorkInformation = () => wrapper.findComponent({ ref: 'workInformation' });
    const findBio = () => wrapper.findComponent({ ref: 'bio' });
    const bio = 'My super interesting bio';

    it('should show only bio if work information is not available', () => {
      const user = { ...DEFAULT_PROPS.user, bio };

      createWrapper({ user });

      expect(findBio().text()).toBe('My super interesting bio');
      expect(findWorkInformation().exists()).toBe(false);
    });

    it('should show work information when it is available', () => {
      const user = {
        ...DEFAULT_PROPS.user,
        workInformation: 'Frontend Engineer at GitLab',
      };

      createWrapper({ user });

      expect(findWorkInformation().text()).toBe('Frontend Engineer at GitLab');
    });

    it('should display bio and work information in separate lines', () => {
      const user = {
        ...DEFAULT_PROPS.user,
        bio,
        workInformation: 'Frontend Engineer at GitLab',
      };

      createWrapper({ user });

      expect(findBio().text()).toBe('My super interesting bio');
      expect(findWorkInformation().text()).toBe('Frontend Engineer at GitLab');
    });

    it('should encode special characters in bio', () => {
      const user = {
        ...DEFAULT_PROPS.user,
        bio: 'I like <b>CSS</b>',
      };

      createWrapper({ user });

      expect(findBio().html()).toContain('I like &lt;b&gt;CSS&lt;/b&gt;');
    });

    it('shows icon for bio', () => {
      const user = {
        ...DEFAULT_PROPS.user,
        bio: 'My super interesting bio',
      };

      createWrapper({ user });

      expect(
        wrapper.findAllComponents(GlIcon).filter((icon) => icon.props('name') === 'profile').length,
      ).toEqual(1);
    });

    it('shows icon for work information', () => {
      const user = {
        ...DEFAULT_PROPS.user,
        workInformation: 'GitLab',
      };

      createWrapper({ user });

      expect(
        wrapper.findAllComponents(GlIcon).filter((icon) => icon.props('name') === 'work').length,
      ).toEqual(1);
    });
  });

  describe('local time', () => {
    it('should show local time when it is available', () => {
      createWrapper();

      expect(findUserLocalTime().exists()).toBe(true);
    });

    it('should not show local time when it is not available', () => {
      const user = {
        ...DEFAULT_PROPS.user,
        localTime: null,
      };

      createWrapper({ user });

      expect(findUserLocalTime().exists()).toBe(false);
    });
  });

  describe('status data', () => {
    it('should show only message', () => {
      const user = { ...DEFAULT_PROPS.user, status: { message_html: 'Hello World' } };

      createWrapper({ user });

      expect(findUserStatus().exists()).toBe(true);
      expect(wrapper.text()).toContain('Hello World');
    });

    it('should show message and emoji', () => {
      const user = {
        ...DEFAULT_PROPS.user,
        status: { emoji: 'basketball_player', message_html: 'Hello World' },
      };

      createWrapper({ user });

      expect(findUserStatus().exists()).toBe(true);
      expect(wrapper.text()).toContain('Hello World');
      expect(wrapper.html()).toContain('<gl-emoji data-name="basketball_player"');
    });

    it('hides the div when status is null', () => {
      const user = { ...DEFAULT_PROPS.user, status: null };

      createWrapper({ user });

      expect(findUserStatus().exists()).toBe(false);
    });

    it('hides the div when status is empty', () => {
      const user = { ...DEFAULT_PROPS.user, status: { emoji: '', message_html: '' } };

      createWrapper({ user });

      expect(findUserStatus().exists()).toBe(false);
    });

    it('should show the busy status if user set to busy', () => {
      const user = {
        ...DEFAULT_PROPS.user,
        status: { availability: AVAILABILITY_STATUS.BUSY },
      };

      createWrapper({ user });

      expect(wrapper.findByText('(Busy)').exists()).toBe(true);
    });

    it('should hide the busy status for any other status', () => {
      const user = {
        ...DEFAULT_PROPS.user,
        status: { availability: AVAILABILITY_STATUS.NOT_SET },
      };

      createWrapper({ user });

      expect(wrapper.findByText('(Busy)').exists()).toBe(false);
    });

    it('shows pronouns when user has them set', () => {
      createWrapper();

      expect(wrapper.findByText('(they/them)').exists()).toBe(true);
    });

    describe.each`
      pronouns
      ${undefined}
      ${null}
      ${''}
      ${'   '}
    `('when pronouns are set to $pronouns', ({ pronouns }) => {
      it('does not render pronouns', () => {
        const user = {
          ...DEFAULT_PROPS.user,
          pronouns,
        };

        createWrapper({ user });

        expect(wrapper.findByTestId('user-popover-pronouns').exists()).toBe(false);
      });
    });
  });

  describe('bot user', () => {
    const SECURITY_BOT_USER = {
      ...DEFAULT_PROPS.user,
      name: 'GitLab Security Bot',
      username: 'GitLab-Security-Bot',
      websiteUrl: '/security/bot/docs',
      bot: true,
    };

    it("shows a link to the bot's documentation", () => {
      createWrapper({ user: SECURITY_BOT_USER });
      const securityBotDocsLink = findSecurityBotDocsLink();
      expect(securityBotDocsLink.exists()).toBe(true);
      expect(securityBotDocsLink.attributes('href')).toBe(SECURITY_BOT_USER.websiteUrl);
      expect(securityBotDocsLink.text()).toBe('Learn more about GitLab Security Bot');
    });

    it("does not show a link to the bot's documentation if there is no website_url", () => {
      createWrapper({ user: { ...SECURITY_BOT_USER, websiteUrl: null } });
      const securityBotDocsLink = findSecurityBotDocsLink();
      expect(securityBotDocsLink.exists()).toBe(false);
    });

    it("doesn't escape user's name", () => {
      createWrapper({ user: { ...SECURITY_BOT_USER, name: '%<>\';"' } });
      const securityBotDocsLink = findSecurityBotDocsLink();
      expect(securityBotDocsLink.text()).toBe('Learn more about %<>\';"');
    });

    it('does not display local time', () => {
      createWrapper({ user: SECURITY_BOT_USER });

      expect(findUserLocalTime().exists()).toBe(false);
    });
  });

  describe("when current user doesn't follow the user", () => {
    beforeEach(() => createWrapper());

    it('renders the Follow button with the correct variant', () => {
      expect(findToggleFollowButton().text()).toBe('Follow');
      expect(findToggleFollowButton().props('variant')).toBe('confirm');
    });

    describe('when clicking', () => {
      it('follows the user', async () => {
        followUser.mockResolvedValue({});

        await findToggleFollowButton().trigger('click');

        expect(findToggleFollowButton().props('loading')).toBe(true);

        await axios.waitForAll();

        expect(wrapper.emitted().follow.length).toBe(1);
        expect(wrapper.emitted().unfollow).toBeFalsy();
      });

      itTracksToggleFollowButtonClick('follow_from_user_popover');

      describe('when an error occurs', () => {
        beforeEach(() => {
          followUser.mockRejectedValue({});

          findToggleFollowButton().trigger('click');
        });

        it('shows an error message', async () => {
          await axios.waitForAll();

          expect(createFlash).toHaveBeenCalledWith({
            message: 'An error occurred while trying to follow this user, please try again.',
            error: {},
            captureError: true,
          });
        });

        it('emits no events', async () => {
          await axios.waitForAll();

          expect(wrapper.emitted().follow).toBe(undefined);
          expect(wrapper.emitted().unfollow).toBe(undefined);
        });
      });
    });
  });

  describe('when current user follows the user', () => {
    beforeEach(() => createWrapper({ user: { ...DEFAULT_PROPS.user, isFollowed: true } }));

    it('renders the Unfollow button with the correct variant', () => {
      expect(findToggleFollowButton().text()).toBe('Unfollow');
      expect(findToggleFollowButton().props('variant')).toBe('default');
    });

    describe('when clicking', () => {
      it('unfollows the user', async () => {
        unfollowUser.mockResolvedValue({});

        findToggleFollowButton().trigger('click');

        await axios.waitForAll();

        expect(wrapper.emitted().follow).toBe(undefined);
        expect(wrapper.emitted().unfollow.length).toBe(1);
      });

      itTracksToggleFollowButtonClick('unfollow_from_user_popover');

      describe('when an error occurs', () => {
        beforeEach(async () => {
          unfollowUser.mockRejectedValue({});

          findToggleFollowButton().trigger('click');

          await axios.waitForAll();
        });

        it('shows an error message', () => {
          expect(createFlash).toHaveBeenCalledWith({
            message: 'An error occurred while trying to unfollow this user, please try again.',
            error: {},
            captureError: true,
          });
        });

        it('emits no events', () => {
          expect(wrapper.emitted().follow).toBe(undefined);
          expect(wrapper.emitted().unfollow).toBe(undefined);
        });
      });
    });
  });

  describe('when the current user is the user', () => {
    beforeEach(() => {
      gon.current_username = DEFAULT_PROPS.user.username;
      createWrapper();
    });

    it("doesn't render the toggle follow button", () => {
      expect(findToggleFollowButton().exists()).toBe(false);
    });
  });

  describe('when API does not support `isFollowed`', () => {
    beforeEach(() => {
      const user = {
        ...DEFAULT_PROPS.user,
        isFollowed: undefined,
      };

      createWrapper({ user });
    });

    it('does not render the toggle follow button', () => {
      expect(findToggleFollowButton().exists()).toBe(false);
    });
  });
});
