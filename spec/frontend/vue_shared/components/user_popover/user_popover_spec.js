import { GlSkeletonLoading, GlSprintf } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import UserPopover from '~/vue_shared/components/user_popover/user_popover.vue';
import Icon from '~/vue_shared/components/icon.vue';

const DEFAULT_PROPS = {
  user: {
    username: 'root',
    name: 'Administrator',
    location: 'Vienna',
    bio: null,
    workInformation: null,
    status: null,
    loaded: true,
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

  describe('when user is loading', () => {
    it('displays skeleton loaders', () => {
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

      expect(wrapper.findAll(GlSkeletonLoading)).toHaveLength(4);
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

      expect(wrapper.findAll(Icon).filter(icon => icon.props('name') === 'profile').length).toEqual(
        1,
      );
    });

    it('shows icon for work information', () => {
      const user = {
        ...DEFAULT_PROPS.user,
        workInformation: 'GitLab',
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
