import { GlAvatar, GlDisclosureDropdown } from '@gitlab/ui';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import UserMenu from '~/super_sidebar/components/user_menu.vue';
import UserNameGroup from '~/super_sidebar/components/user_name_group.vue';
import NewNavToggle from '~/nav/components/new_nav_toggle.vue';
import invalidUrl from '~/lib/utils/invalid_url';
import { mockTracking } from 'helpers/tracking_helper';
import PersistentUserCallout from '~/persistent_user_callout';
import { userMenuMockData, userMenuMockStatus, userMenuMockPipelineMinutes } from '../mock_data';

describe('UserMenu component', () => {
  let wrapper;
  let trackingSpy;

  const GlEmoji = { template: '<img/>' };
  const toggleNewNavEndpoint = invalidUrl;
  const findDropdown = () => wrapper.findComponent(GlDisclosureDropdown);
  const showDropdown = () => findDropdown().vm.$emit('shown');

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

    trackingSpy = mockTracking(undefined, wrapper.element, jest.spyOn);
  };

  it('passes popper options to the dropdown', () => {
    createWrapper();

    expect(findDropdown().props('popperOptions')).toEqual({
      modifiers: [{ name: 'offset', options: { offset: [-211, 4] } }],
    });
  });

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

      it('should close the dropdown when status modal opened', () => {
        setItem({ can_update: true });
        wrapper.vm.$refs.userDropdown.close = jest.fn();
        expect(wrapper.vm.$refs.userDropdown.close).not.toHaveBeenCalled();
        item.vm.$emit('action');
        expect(wrapper.vm.$refs.userDropdown.close).toHaveBeenCalled();
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

        describe('when user cannot update status', () => {
          it('sets default data attributes', () => {
            setItem({ can_update: true });
            expect(findModalWrapper().attributes()).toMatchObject({
              'data-current-emoji': '',
              'data-current-message': '',
              'data-default-emoji': 'speech_balloon',
            });
          });
        });

        describe.each`
          busy     | customized
          ${true}  | ${true}
          ${true}  | ${false}
          ${false} | ${true}
          ${false} | ${false}
        `(`when user can update status`, ({ busy, customized }) => {
          it(`and ${busy ? 'is busy' : 'is not busy'} and status ${
            customized ? 'is' : 'is not'
          } customized sets user status data attributes`, () => {
            setItem({ can_update: true, busy, customized });
            if (busy || customized) {
              expect(findModalWrapper().attributes()).toMatchObject({
                'data-current-emoji': userMenuMockStatus.emoji,
                'data-current-message': userMenuMockStatus.message,
                'data-current-availability': userMenuMockStatus.availability,
                'data-current-clear-status-after': userMenuMockStatus.clear_after,
              });
            } else {
              expect(findModalWrapper().attributes()).toMatchObject({
                'data-current-emoji': '',
                'data-current-message': '',
                'data-default-emoji': 'speech_balloon',
              });
            }
          });
        });
      });
    });
  });

  describe('Start Ultimate trial item', () => {
    let item;

    const setItem = ({ has_start_trial } = {}) => {
      createWrapper({ trial: { has_start_trial, url: '' } });
      item = wrapper.findByTestId('start-trial-item');
    };

    describe('When Ultimate trial is not suggested for the user', () => {
      it('does not render the start trial menu item', () => {
        setItem();
        expect(item.exists()).toBe(false);
      });
    });

    describe('When Ultimate trial can be suggested for the user', () => {
      it('does render the start trial menu item', () => {
        setItem({ has_start_trial: true });
        expect(item.exists()).toBe(true);
      });
    });

    it('has Snowplow tracking attributes', () => {
      setItem({ has_start_trial: true });
      expect(item.find('a').attributes()).toMatchObject({
        'data-track-property': 'nav_user_menu',
        'data-track-action': 'click_link',
        'data-track-label': 'start_trial',
      });
    });

    describe('When trial info is not provided', () => {
      it('does not render the start trial menu item', () => {
        createWrapper();

        expect(wrapper.findByTestId('start-trial-item').exists()).toBe(false);
      });
    });
  });

  describe('Buy Pipeline Minutes item', () => {
    let item;

    const setItem = ({
      show_buy_pipeline_minutes,
      show_with_subtext,
      show_notification_dot,
    } = {}) => {
      createWrapper({
        pipeline_minutes: {
          ...userMenuMockPipelineMinutes,
          show_buy_pipeline_minutes,
          show_with_subtext,
          show_notification_dot,
        },
      });
      item = wrapper.findByTestId('buy-pipeline-minutes-item');
    };

    describe('When does NOT meet the condition to buy CI minutes', () => {
      beforeEach(() => {
        setItem();
      });

      it('does NOT render the buy pipeline minutes item', () => {
        expect(item.exists()).toBe(false);
      });

      it('does not track the Sentry event', () => {
        showDropdown();
        expect(trackingSpy).not.toHaveBeenCalled();
      });
    });

    describe('When does meet the condition to buy CI minutes', () => {
      it('does render the menu item', () => {
        setItem({ show_buy_pipeline_minutes: true });
        expect(item.exists()).toBe(true);
      });

      describe('Snowplow tracking attributes to track item click', () => {
        beforeEach(() => {
          setItem({ show_buy_pipeline_minutes: true });
        });

        it('has attributes to track item click in scope of new nav', () => {
          expect(item.find('a').attributes()).toMatchObject({
            'data-track-property': 'nav_user_menu',
            'data-track-action': 'click_link',
            'data-track-label': 'buy_pipeline_minutes',
          });
        });

        it('tracks the click on the item', () => {
          item.vm.$emit('action');
          expect(trackingSpy).toHaveBeenCalledWith(
            undefined,
            userMenuMockPipelineMinutes.tracking_attrs['track-action'],
            {
              label: userMenuMockPipelineMinutes.tracking_attrs['track-label'],
              property: userMenuMockPipelineMinutes.tracking_attrs['track-property'],
            },
          );
        });
      });

      describe('Callout & notification dot', () => {
        let spyFactory;

        beforeEach(() => {
          spyFactory = jest.spyOn(PersistentUserCallout, 'factory');
        });

        describe('When `show_notification_dot` is `false`', () => {
          beforeEach(() => {
            setItem({ show_buy_pipeline_minutes: true, show_notification_dot: false });
            showDropdown();
          });

          it('does not set callout attributes', () => {
            expect(item.attributes()).not.toEqual(
              expect.objectContaining({
                'data-feature-id': userMenuMockPipelineMinutes.callout_attrs.feature_id,
                'data-dismiss-endpoint': userMenuMockPipelineMinutes.callout_attrs.dismiss_endpoint,
              }),
            );
          });

          it('does not initialize the Persistent Callout', () => {
            expect(spyFactory).not.toHaveBeenCalled();
          });

          it('does not render notification dot', () => {
            expect(wrapper.findByTestId('buy-pipeline-minutes-notification-dot').exists()).toBe(
              false,
            );
          });
        });

        describe('When `show_notification_dot` is `true`', () => {
          beforeEach(() => {
            setItem({ show_buy_pipeline_minutes: true, show_notification_dot: true });
            showDropdown();
          });

          it('sets the callout data attributes', () => {
            expect(item.attributes()).toEqual(
              expect.objectContaining({
                'data-feature-id': userMenuMockPipelineMinutes.callout_attrs.feature_id,
                'data-dismiss-endpoint': userMenuMockPipelineMinutes.callout_attrs.dismiss_endpoint,
              }),
            );
          });

          it('initializes the Persistent Callout', () => {
            expect(spyFactory).toHaveBeenCalled();
          });

          it('renders notification dot', () => {
            expect(wrapper.findByTestId('buy-pipeline-minutes-notification-dot').exists()).toBe(
              true,
            );
          });
        });
      });

      describe('Warning message', () => {
        it('does not display the warning message when `show_with_subtext` is `false`', () => {
          setItem({ show_buy_pipeline_minutes: true });

          expect(item.text()).not.toContain(UserMenu.i18n.oneOfGroupsRunningOutOfPipelineMinutes);
        });

        it('displays the text and warning message when `show_with_subtext` is true', () => {
          setItem({ show_buy_pipeline_minutes: true, show_with_subtext: true });

          expect(item.text()).toContain(UserMenu.i18n.oneOfGroupsRunningOutOfPipelineMinutes);
        });
      });
    });
  });

  describe('Edit profile item', () => {
    let item;

    beforeEach(() => {
      createWrapper();
      item = wrapper.findByTestId('edit-profile-item');
    });

    it('should render a link to the profile page', () => {
      expect(item.text()).toBe(UserMenu.i18n.editProfile);
      expect(item.find('a').attributes('href')).toBe(userMenuMockData.settings.profile_path);
    });

    it('has Snowplow tracking attributes', () => {
      expect(item.find('a').attributes()).toMatchObject({
        'data-track-property': 'nav_user_menu',
        'data-track-action': 'click_link',
        'data-track-label': 'user_edit_profile',
      });
    });
  });

  describe('Preferences item', () => {
    let item;

    beforeEach(() => {
      createWrapper();
      item = wrapper.findByTestId('preferences-item');
    });

    it('should render a link to the profile page', () => {
      expect(item.text()).toBe(UserMenu.i18n.preferences);
      expect(item.find('a').attributes('href')).toBe(
        userMenuMockData.settings.profile_preferences_path,
      );
    });

    it('has Snowplow tracking attributes', () => {
      expect(item.find('a').attributes()).toMatchObject({
        'data-track-property': 'nav_user_menu',
        'data-track-action': 'click_link',
        'data-track-label': 'user_preferences',
      });
    });
  });

  describe('GitLab Next item', () => {
    describe('on gitlab.com', () => {
      let item;

      beforeEach(() => {
        createWrapper({ gitlab_com_but_not_canary: true });
        item = wrapper.findByTestId('gitlab-next-item');
      });
      it('should render a link to switch to GitLab Next', () => {
        expect(item.text()).toBe(UserMenu.i18n.gitlabNext);
        expect(item.find('a').attributes('href')).toBe(userMenuMockData.canary_toggle_com_url);
      });

      it('has Snowplow tracking attributes', () => {
        expect(item.find('a').attributes()).toMatchObject({
          'data-track-property': 'nav_user_menu',
          'data-track-action': 'click_link',
          'data-track-label': 'switch_to_canary',
        });
      });
    });

    describe('anywhere else', () => {
      it('should not render the GitLab Next link', () => {
        createWrapper({ gitlab_com_but_not_canary: false });
        const item = wrapper.findByTestId('gitlab-next-item');
        expect(item.exists()).toBe(false);
      });
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
    let item;

    beforeEach(() => {
      createWrapper();
      item = wrapper.findByTestId('feedback-item');
    });

    it('should render feedback item with a link to a new GitLab issue', () => {
      expect(item.find('a').attributes('href')).toBe(UserMenu.feedbackUrl);
    });

    it('has Snowplow tracking attributes', () => {
      expect(item.find('a').attributes()).toMatchObject({
        'data-track-property': 'nav_user_menu',
        'data-track-action': 'click_link',
        'data-track-label': 'provide_nav_beta_feedback',
      });
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

      it('should track Snowplow event on sign out', () => {
        findSignOutGroup().vm.$emit('action');

        expect(trackingSpy).toHaveBeenCalledWith(undefined, 'click_link', {
          label: 'user_sign_out',
          property: 'nav_user_menu',
        });
      });
    });
  });
});
