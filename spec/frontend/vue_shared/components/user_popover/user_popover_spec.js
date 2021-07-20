import { GlSkeletonLoader, GlIcon } from '@gitlab/ui';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import { AVAILABILITY_STATUS } from '~/set_status_modal/utils';
import UserNameWithStatus from '~/sidebar/components/assignees/user_name_with_status.vue';
import UserPopover from '~/vue_shared/components/user_popover/user_popover.vue';

const DEFAULT_PROPS = {
  user: {
    username: 'root',
    name: 'Administrator',
    location: 'Vienna',
    bot: false,
    bio: null,
    workInformation: null,
    status: null,
    pronouns: 'they/them',
    loaded: true,
  },
};

describe('User Popover Component', () => {
  const fixtureTemplate = 'merge_requests/diff_comment.html';

  let wrapper;

  beforeEach(() => {
    loadFixtures(fixtureTemplate);
  });

  afterEach(() => {
    wrapper.destroy();
  });

  const findUserStatus = () => wrapper.find('.js-user-status');
  const findTarget = () => document.querySelector('.js-user-link');
  const findUserName = () => wrapper.find(UserNameWithStatus);
  const findSecurityBotDocsLink = () => wrapper.findByTestId('user-popover-bot-docs-link');

  const createWrapper = (props = {}, options = {}) => {
    wrapper = mountExtended(UserPopover, {
      propsData: {
        ...DEFAULT_PROPS,
        target: findTarget(),
        ...props,
      },
      ...options,
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

      expect(wrapper.find(GlSkeletonLoader).exists()).toBe(true);
    });
  });

  describe('basic data', () => {
    it('should show basic fields', () => {
      createWrapper();

      expect(wrapper.text()).toContain(DEFAULT_PROPS.user.name);
      expect(wrapper.text()).toContain(DEFAULT_PROPS.user.username);
      expect(wrapper.text()).toContain(DEFAULT_PROPS.user.location);
    });

    it('shows icon for location', () => {
      createWrapper();
      const iconEl = wrapper.find(GlIcon);

      expect(iconEl.props('name')).toEqual('location');
    });

    it("should not show a link to bot's documentation", () => {
      createWrapper();
      const securityBotDocsLink = findSecurityBotDocsLink();
      expect(securityBotDocsLink.exists()).toBe(false);
    });
  });

  describe('job data', () => {
    const findWorkInformation = () => wrapper.find({ ref: 'workInformation' });
    const findBio = () => wrapper.find({ ref: 'bio' });
    const bio = 'My super interesting bio';

    it('should show only bio if work information is not available', () => {
      const user = { ...DEFAULT_PROPS.user, bio, bioHtml: bio };

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
        bioHtml: bio,
        workInformation: 'Frontend Engineer at GitLab',
      };

      createWrapper({ user });

      expect(findBio().text()).toBe('My super interesting bio');
      expect(findWorkInformation().text()).toBe('Frontend Engineer at GitLab');
    });

    it('should not encode special characters in bio', () => {
      const user = {
        ...DEFAULT_PROPS.user,
        bio: 'I like CSS',
        bioHtml: 'I like <b>CSS</b>',
      };

      createWrapper({ user });

      expect(findBio().html()).toContain('I like <b>CSS</b>');
    });

    it('shows icon for bio', () => {
      const user = {
        ...DEFAULT_PROPS.user,
        bio: 'My super interesting bio',
      };

      createWrapper({ user });

      expect(
        wrapper.findAll(GlIcon).filter((icon) => icon.props('name') === 'profile').length,
      ).toEqual(1);
    });

    it('shows icon for work information', () => {
      const user = {
        ...DEFAULT_PROPS.user,
        workInformation: 'GitLab',
      };

      createWrapper({ user });

      expect(
        wrapper.findAll(GlIcon).filter((icon) => icon.props('name') === 'work').length,
      ).toEqual(1);
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

      expect(findUserName().exists()).toBe(true);
      expect(wrapper.text()).toContain(user.name);
      expect(wrapper.text()).toContain('(Busy)');
    });

    it('should hide the busy status for any other status', () => {
      const user = {
        ...DEFAULT_PROPS.user,
        status: { availability: AVAILABILITY_STATUS.NOT_SET },
      };

      createWrapper({ user });

      expect(wrapper.text()).not.toContain('(Busy)');
    });

    it('passes `pronouns` prop to `UserNameWithStatus` component', () => {
      createWrapper();

      expect(findUserName().props('pronouns')).toBe('they/them');
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
    });
  });
});
