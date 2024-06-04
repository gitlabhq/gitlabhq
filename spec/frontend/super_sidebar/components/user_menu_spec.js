import { GlAvatar, GlDisclosureDropdown } from '@gitlab/ui';
import { nextTick } from 'vue';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import { stubComponent } from 'helpers/stub_component';
import UserMenu from '~/super_sidebar/components/user_menu.vue';
import UserMenuProfileItem from '~/super_sidebar/components/user_menu_profile_item.vue';
import SetStatusModal from '~/set_status_modal/set_status_modal_wrapper.vue';
import { mockTracking } from 'helpers/tracking_helper';
import PersistentUserCallout from '~/persistent_user_callout';
import { userMenuMockData, userMenuMockStatus, userMenuMockPipelineMinutes } from '../mock_data';

describe('UserMenu component', () => {
  let wrapper;
  let trackingSpy;

  const GlEmoji = { template: '<img/>' };
  const findDropdown = () => wrapper.findComponent(GlDisclosureDropdown);
  const findSetStatusModal = () => wrapper.findComponent(SetStatusModal);
  const showDropdown = () => findDropdown().vm.$emit('shown');

  const closeDropdownSpy = jest.fn();

  const createWrapper = (userDataChanges = {}, stubs = {}, provide = {}) => {
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
        SetStatusModal: stubComponent(SetStatusModal),
        ...stubs,
      },
      provide: {
        isImpersonating: false,
        ...provide,
      },
    });

    trackingSpy = mockTracking(undefined, wrapper.element, jest.spyOn);
  };

  it('passes custom offset to the dropdown', () => {
    createWrapper();

    expect(findDropdown().props('dropdownOffset')).toEqual({
      crossAxis: -211,
      mainAxis: 4,
    });
  });

  it('decreases the dropdown offset when impersonating a user', () => {
    createWrapper(null, null, { isImpersonating: true });

    expect(findDropdown().props('dropdownOffset')).toEqual({
      crossAxis: -177,
      mainAxis: 4,
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

    it('updates avatar url on custom avatar update event', async () => {
      const url = `${userMenuMockData.avatar_url}-new-avatar`;

      document.dispatchEvent(new CustomEvent('userAvatar:update', { detail: { url } }));
      await nextTick();

      const avatar = toggle.findComponent(GlAvatar);
      expect(avatar.exists()).toBe(true);
      expect(avatar.props()).toMatchObject({
        entityName: userMenuMockData.name,
        src: url,
      });
    });

    it('renders screen reader text', () => {
      expect(toggle.find('.gl-sr-only').text()).toBe(`${userMenuMockData.name} user’s menu`);
    });
  });

  describe('User Menu Group', () => {
    it('renders and passes data to it', () => {
      createWrapper();
      const userMenuProfileItem = wrapper.findComponent(UserMenuProfileItem);
      expect(userMenuProfileItem.exists()).toBe(true);
      expect(userMenuProfileItem.props('user')).toEqual(userMenuMockData);
    });
  });

  describe('User status item', () => {
    let item;

    const setItem = async ({
      can_update: canUpdate = false,
      busy = false,
      customized = false,
      stubs,
    } = {}) => {
      createWrapper(
        { status: { ...userMenuMockStatus, can_update: canUpdate, busy, customized } },
        stubs,
      );
      // Mock mounting the modal if we can update
      if (canUpdate) {
        expect(wrapper.vm.setStatusModalReady).toEqual(false);
        findSetStatusModal().vm.$emit('mounted');
        await nextTick();
        expect(wrapper.vm.setStatusModalReady).toEqual(true);
      }
      item = wrapper.findByTestId('status-item');
    };

    describe('When user cannot update the status', () => {
      it('does not render the status menu item', async () => {
        await setItem();
        expect(item.exists()).toBe(false);
      });
    });

    describe('When user can update the status', () => {
      it('renders the status menu item', async () => {
        await setItem({ can_update: true });
        expect(item.exists()).toBe(true);
        expect(item.find('button').attributes()).toMatchObject({
          'data-track-property': 'nav_user_menu',
          'data-track-action': 'click_link',
          'data-track-label': 'user_edit_status',
        });
      });

      it('should close the dropdown when status modal opened', async () => {
        await setItem({
          can_update: true,
          stubs: {
            GlDisclosureDropdown: stubComponent(GlDisclosureDropdown, {
              methods: {
                close: closeDropdownSpy,
              },
            }),
          },
        });
        expect(closeDropdownSpy).not.toHaveBeenCalled();
        item.vm.$emit('action');
        expect(closeDropdownSpy).toHaveBeenCalled();
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
          async ({ busy, customized, label }) => {
            await setItem({ can_update: true, busy, customized });
            expect(item.text()).toBe(label);
          },
        );
      });
    });
  });

  describe('set status modal', () => {
    describe('when the user cannot update the status', () => {
      it('should not render the modal', () => {
        createWrapper({
          status: { ...userMenuMockStatus, can_update: false },
        });

        expect(findSetStatusModal().exists()).toBe(false);
      });
    });

    describe('when the user can update the status', () => {
      describe.each`
        busy     | customized
        ${true}  | ${true}
        ${true}  | ${false}
        ${false} | ${true}
      `('and the status is busy or customized', ({ busy, customized }) => {
        it('should pass the current status to the modal', () => {
          createWrapper({
            status: { ...userMenuMockStatus, can_update: true, busy, customized },
          });

          expect(findSetStatusModal().exists()).toBe(true);
          expect(findSetStatusModal().props()).toMatchObject({
            defaultEmoji: 'speech_balloon',
            currentEmoji: userMenuMockStatus.emoji,
            currentMessage: userMenuMockStatus.message,
            currentAvailability: userMenuMockStatus.availability,
            currentClearStatusAfter: userMenuMockStatus.clear_after,
          });
        });

        it('casts falsey values to empty strings', () => {
          createWrapper({
            status: { can_update: true, busy, customized },
          });

          expect(findSetStatusModal().exists()).toBe(true);
          expect(findSetStatusModal().props()).toMatchObject({
            defaultEmoji: 'speech_balloon',
            currentEmoji: '',
            currentMessage: '',
            currentAvailability: '',
            currentClearStatusAfter: '',
          });
        });
      });

      describe('and the status is neither busy nor customized', () => {
        it('should pass an empty status to the modal', () => {
          createWrapper({
            status: { ...userMenuMockStatus, can_update: true, busy: false, customized: false },
          });

          expect(findSetStatusModal().exists()).toBe(true);
          expect(findSetStatusModal().props()).toMatchObject({
            defaultEmoji: 'speech_balloon',
            currentEmoji: '',
            currentMessage: '',
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

  describe('Buy compute minutes item', () => {
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

    describe('When does NOT meet the condition to buy compute minutes', () => {
      beforeEach(() => {
        setItem();
      });

      it('does NOT render the buy compute minutes item', () => {
        expect(item.exists()).toBe(false);
      });

      it('does not track the Sentry event', () => {
        showDropdown();
        expect(trackingSpy).not.toHaveBeenCalled();
      });
    });

    describe('When does meet the condition to buy compute minutes', () => {
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

  describe('Admin Mode items', () => {
    const findEnterAdminModeItem = () => wrapper.findByTestId('enter-admin-mode-item');
    const findLeaveAdminModeItem = () => wrapper.findByTestId('leave-admin-mode-item');

    describe('when user is not admin', () => {
      it('should not render', () => {
        createWrapper({
          admin_mode: {
            user_is_admin: false,
          },
        });
        expect(findEnterAdminModeItem().exists()).toBe(false);
        expect(findLeaveAdminModeItem().exists()).toBe(false);
      });
    });

    describe('when user is admin but admin mode feature is not enabled', () => {
      it('should not render', () => {
        createWrapper({
          admin_mode: {
            user_is_admin: true,
            admin_mode_feature_enabled: false,
          },
        });
        expect(findEnterAdminModeItem().exists()).toBe(false);
        expect(findLeaveAdminModeItem().exists()).toBe(false);
      });
    });

    describe('when user is admin, admin mode feature is enabled but inactive', () => {
      it('should render only "enter admin mode" item', () => {
        createWrapper({
          admin_mode: {
            user_is_admin: true,
            admin_mode_feature_enabled: true,
            admin_mode_active: false,
          },
        });
        expect(findEnterAdminModeItem().exists()).toBe(true);
        expect(findLeaveAdminModeItem().exists()).toBe(false);
      });
    });

    describe('when user is admin, admin mode feature is enabled and active', () => {
      it('should render only "leave admin mode" item', () => {
        createWrapper({
          admin_mode: {
            user_is_admin: true,
            admin_mode_feature_enabled: true,
            admin_mode_active: true,
          },
        });
        expect(findEnterAdminModeItem().exists()).toBe(false);
        expect(findLeaveAdminModeItem().exists()).toBe(true);
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
