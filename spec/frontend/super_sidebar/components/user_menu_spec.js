import { GlAvatar } from '@gitlab/ui';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import UserMenu from '~/super_sidebar/components/user_menu.vue';
import UserNameGroup from '~/super_sidebar/components/user_name_group.vue';
import NewNavToggle from '~/nav/components/new_nav_toggle.vue';
import invalidUrl from '~/lib/utils/invalid_url';
import { userMenuMockData, userMenuMockStatus } from '../mock_data';

describe('UserMenu component', () => {
  let wrapper;

  const GlEmoji = { template: '<img/>' };
  const toggleNewNavEndpoint = invalidUrl;

  const createWrapper = (userDataChanges = {}) => {
    wrapper = mountExtended(UserMenu, {
      propsData: {
        data: {
          ...userMenuMockData,
          ...userDataChanges,
        },
      },
      stubs: {
        GlEmoji,
        GlAvatar: true,
      },
      provide: {
        toggleNewNavEndpoint,
      },
    });
  };

  describe('Toggle button', () => {
    let toggle;

    beforeEach(() => {
      createWrapper();
      toggle = wrapper.findByTestId('base-dropdown-toggle');
    });

    it('renders User Avatar in a toggle', () => {
      const avatar = toggle.findComponent(GlAvatar);
      expect(avatar.exists()).toBe(true);
      expect(avatar.props()).toMatchObject({
        entityName: userMenuMockData.name,
        src: userMenuMockData.avatar_url,
      });
    });

    it('renders screen reader text', () => {
      expect(toggle.find('.gl-sr-only').text()).toBe(`${userMenuMockData.name} user’s menu`);
    });
  });

  describe('User Menu Group', () => {
    it('renders and passes data to it', () => {
      createWrapper();
      const userNameGroup = wrapper.findComponent(UserNameGroup);
      expect(userNameGroup.exists()).toBe(true);
      expect(userNameGroup.props('user')).toEqual(userMenuMockData);
    });
  });

  describe('User status item', () => {
    let item;

    const setItem = ({ can_update, busy, customized } = {}) => {
      createWrapper({ status: { ...userMenuMockStatus, can_update, busy, customized } });
      item = wrapper.findByTestId('status-item');
    };

    describe('When user cannot update the status', () => {
      it('does not render the status menu item', () => {
        setItem();
        expect(item.exists()).toBe(false);
      });
    });

    describe('When user can update the status', () => {
      it('renders the status menu item', () => {
        setItem({ can_update: true });
        expect(item.exists()).toBe(true);
      });

      it('should set the CSS class for triggering status update modal', () => {
        setItem({ can_update: true });
        expect(item.find('.js-set-status-modal-trigger').exists()).toBe(true);
      });

      describe('renders correct label', () => {
        it.each`
          busy     | customized | label
          ${false} | ${false}   | ${'Set status'}
          ${false} | ${true}    | ${'Edit status'}
          ${true}  | ${false}   | ${'Edit status'}
          ${true}  | ${true}    | ${'Edit status'}
        `(
          'when busy is "$busy" and customized is "$customized" the label is "$label"',
          ({ busy, customized, label }) => {
            setItem({ can_update: true, busy, customized });
            expect(item.text()).toBe(label);
          },
        );
      });

      describe('Status update modal wrapper', () => {
        const findModalWrapper = () => wrapper.find('.js-set-status-modal-wrapper');

        it('renders the modal wrapper', () => {
          setItem({ can_update: true });
          expect(findModalWrapper().exists()).toBe(true);
        });

        it('sets default data attributes when status is not customized', () => {
          setItem({ can_update: true });
          expect(findModalWrapper().attributes()).toMatchObject({
            'data-current-emoji': '',
            'data-current-message': '',
            'data-default-emoji': 'speech_balloon',
          });
        });

        it('sets user status as data attributes when status is customized', () => {
          setItem({ can_update: true, customized: true });
          expect(findModalWrapper().attributes()).toMatchObject({
            'data-current-emoji': userMenuMockStatus.emoji,
            'data-current-message': userMenuMockStatus.message,
            'data-current-availability': userMenuMockStatus.availability,
            'data-current-clear-status-after': userMenuMockStatus.clear_after,
          });
        });
      });
    });
  });

  describe('Start Ultimate trial item', () => {
    let item;

    const setItem = ({ has_start_trial } = {}) => {
      createWrapper({ status: { ...userMenuMockStatus, has_start_trial } });
      item = wrapper.findByTestId('start-trial-item');
    };

    describe('When Ultimate trial is not suggested for the user', () => {
      it('does not render the start triel menu item', () => {
        setItem();
        expect(item.exists()).toBe(false);
      });
    });

    describe('When Ultimate trial can be suggested for the user', () => {
      it('does not render the status menu item', () => {
        setItem({ has_start_trial: true });
        expect(item.exists()).toBe(false);
      });
    });
  });

  describe('Edit profile item', () => {
    it('should render a link to the profile page', () => {
      createWrapper();
      const item = wrapper.findByTestId('edit-profile-item');
      expect(item.text()).toBe(UserMenu.i18n.user.editProfile);
      expect(item.find('a').attributes('href')).toBe(userMenuMockData.settings.profile_path);
    });
  });

  describe('Preferences item', () => {
    it('should render a link to the profile page', () => {
      createWrapper();
      const item = wrapper.findByTestId('preferences-item');
      expect(item.text()).toBe(UserMenu.i18n.user.preferences);
      expect(item.find('a').attributes('href')).toBe(
        userMenuMockData.settings.profile_preferences_path,
      );
    });
  });

  describe('New navigation toggle item', () => {
    it('should render menu item with new navigation toggle', () => {
      createWrapper();
      const toggleItem = wrapper.findComponent(NewNavToggle);
      expect(toggleItem.exists()).toBe(true);
      expect(toggleItem.props('endpoint')).toBe(toggleNewNavEndpoint);
    });
  });

  describe('Feedback item', () => {
    it('should render feedback item with a link to a new GitLab issue', () => {
      createWrapper();
      const feedbackItem = wrapper.findByTestId('feedback-item');
      expect(feedbackItem.find('a').attributes('href')).toBe(UserMenu.feedbackUrl);
    });
  });

  describe('Sign out group', () => {
    const findSignOutGroup = () => wrapper.findByTestId('sign-out-group');

    it('should not render sign out group when user cannot sign out', () => {
      createWrapper();
      expect(findSignOutGroup().exists()).toBe(false);
    });

    describe('when user can sign out', () => {
      beforeEach(() => {
        createWrapper({ can_sign_out: true });
      });

      it('should render sign out group', () => {
        expect(findSignOutGroup().exists()).toBe(true);
      });

      it('should render the menu item with a link to sign out and correct data attribute', () => {
        expect(findSignOutGroup().find('a').attributes('href')).toBe(
          userMenuMockData.sign_out_link,
        );
        expect(findSignOutGroup().find('a').attributes('data-method')).toBe('post');
      });
    });
  });
});
