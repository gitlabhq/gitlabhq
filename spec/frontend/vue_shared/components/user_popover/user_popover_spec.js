import { GlSkeletonLoading, GlSprintf } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import UserPopover from '~/vue_shared/components/user_popover/user_popover.vue';
import Icon from '~/vue_shared/components/icon.vue';

const DEFAULT_PROPS = {
  loaded: true,
  user: {
    username: 'root',
    name: 'Administrator',
    location: 'Vienna',
    bio: null,
    organization: null,
    jobTitle: null,
    status: null,
  },
};

describe('User Popover Component', () => {
  const fixtureTemplate = 'merge_requests/diff_comment.html';
  preloadFixtures(fixtureTemplate);

  let wrapper;

  beforeEach(() => {
    loadFixtures(fixtureTemplate);
  });

  afterEach(() => {
    wrapper.destroy();
  });

  const findUserStatus = () => wrapper.find('.js-user-status');
  const findTarget = () => document.querySelector('.js-user-link');

  const createWrapper = (props = {}, options = {}) => {
    wrapper = shallowMount(UserPopover, {
      propsData: {
        ...DEFAULT_PROPS,
        target: findTarget(),
        ...props,
      },
      stubs: {
        'gl-sprintf': GlSprintf,
      },
      ...options,
    });
  };

  describe('Empty', () => {
    beforeEach(() => {
      createWrapper(
        {},
        {
          propsData: {
            target: findTarget(),
            user: {
              name: null,
              username: null,
              location: null,
              bio: null,
              organization: null,
              jobTitle: null,
              status: null,
            },
          },
        },
      );
    });

    it('should return skeleton loaders', () => {
      expect(wrapper.find(GlSkeletonLoading).exists()).toBe(true);
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
      const iconEl = wrapper.find(Icon);

      expect(iconEl.props('name')).toEqual('location');
    });
  });

  describe('job data', () => {
    const findWorkInformation = () => wrapper.find({ ref: 'workInformation' });
    const findBio = () => wrapper.find({ ref: 'bio' });

    it('should show only bio if organization and job title are not available', () => {
      const user = { ...DEFAULT_PROPS.user, bio: 'My super interesting bio' };

      createWrapper({ user });

      expect(findBio().text()).toBe('My super interesting bio');
      expect(findWorkInformation().exists()).toBe(false);
    });

    it('should show only organization if job title is not available', () => {
      const user = { ...DEFAULT_PROPS.user, organization: 'GitLab' };

      createWrapper({ user });

      expect(findWorkInformation().text()).toBe('GitLab');
    });

    it('should show only job title if organization is not available', () => {
      const user = { ...DEFAULT_PROPS.user, jobTitle: 'Frontend Engineer' };

      createWrapper({ user });

      expect(findWorkInformation().text()).toBe('Frontend Engineer');
    });

    it('should show organization and job title if they are both available', () => {
      const user = {
        ...DEFAULT_PROPS.user,
        organization: 'GitLab',
        jobTitle: 'Frontend Engineer',
      };

      createWrapper({ user });

      expect(findWorkInformation().text()).toBe('Frontend Engineer at GitLab');
    });

    it('should display bio and job info in separate lines', () => {
      const user = {
        ...DEFAULT_PROPS.user,
        bio: 'My super interesting bio',
        organization: 'GitLab',
      };

      createWrapper({ user });

      expect(findBio().text()).toBe('My super interesting bio');
      expect(findWorkInformation().text()).toBe('GitLab');
    });

    it('should not encode special characters in bio', () => {
      const user = {
        ...DEFAULT_PROPS.user,
        bio: 'I like <html> & CSS',
      };

      createWrapper({ user });

      expect(findBio().text()).toBe('I like <html> & CSS');
    });

    it('should not encode special characters in organization', () => {
      const user = {
        ...DEFAULT_PROPS.user,
        organization: 'Me & my <funky> Company',
      };

      createWrapper({ user });

      expect(findWorkInformation().text()).toBe('Me & my <funky> Company');
    });

    it('should not encode special characters in job title', () => {
      const user = {
        ...DEFAULT_PROPS.user,
        jobTitle: 'Manager & Team Lead',
      };

      createWrapper({ user });

      expect(findWorkInformation().text()).toBe('Manager & Team Lead');
    });

    it('should not encode special characters when both job title and organization are set', () => {
      const user = {
        ...DEFAULT_PROPS.user,
        jobTitle: 'Manager & Team Lead',
        organization: 'Me & my <funky> Company',
      };

      createWrapper({ user });

      expect(findWorkInformation().text()).toBe('Manager & Team Lead at Me & my <funky> Company');
    });

    it('shows icon for bio', () => {
      const user = {
        ...DEFAULT_PROPS.user,
        bio: 'My super interesting bio',
      };

      createWrapper({ user });

      expect(wrapper.findAll(Icon).filter(icon => icon.props('name') === 'profile').length).toEqual(
        1,
      );
    });

    it('shows icon for organization', () => {
      const user = {
        ...DEFAULT_PROPS.user,
        organization: 'GitLab',
      };

      createWrapper({ user });

      expect(wrapper.findAll(Icon).filter(icon => icon.props('name') === 'work').length).toEqual(1);
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
  });
});
