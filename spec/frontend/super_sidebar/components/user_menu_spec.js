import MockAdapter from 'axios-mock-adapter';
import { GlAvatar, GlDisclosureDropdown } from '@gitlab/ui';
import { nextTick } from 'vue';
import axios from '~/lib/utils/axios_utils';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import { stubComponent } from 'helpers/stub_component';
import UserMenu from '~/super_sidebar/components/user_menu.vue';
import UserMenuProfileItem from '~/super_sidebar/components/user_menu_profile_item.vue';
import SetStatusModal from '~/set_status_modal/set_status_modal_wrapper.vue';
import { mockTracking } from 'helpers/tracking_helper';
import { visitUrl } from '~/lib/utils/url_utility';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import { HTTP_STATUS_INTERNAL_SERVER_ERROR, HTTP_STATUS_OK } from '~/lib/utils/http_status';
import waitForPromises from 'helpers/wait_for_promises';
import { logError } from '~/lib/logger';
import { userMenuMockData, userMenuMockStatus, userMenuMockPipelineMinutes } from '../mock_data';

jest.mock('~/sentry/sentry_browser_wrapper');
jest.mock('~/lib/utils/url_utility');
jest.mock('~/lib/logger');

describe('UserMenu component', () => {
  let wrapper;
  let trackingSpy;

  const GlEmoji = { template: '<img/>' };
  const findDropdown = () => wrapper.findComponent(GlDisclosureDropdown);
  const findSetStatusModal = () => wrapper.findComponent(SetStatusModal);
  const showDropdown = () => findDropdown().vm.$emit('shown');
  const findStopImpersonationButton = () => wrapper.findByTestId('stop-impersonation-btn');

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
        GlIcon: true,
        SetStatusModal: stubComponent(SetStatusModal),
        ...stubs,
      },
      provide: {
        isImpersonating: false,
        projectStudioAvailable: false,
        projectStudioEnabled: false,
        ...provide,
      },
    });

    trackingSpy = mockTracking(undefined, wrapper.element, jest.spyOn);
  };

  it('passes custom offset to the dropdown', () => {
    createWrapper();

    expect(findDropdown().props('dropdownOffset')).toEqual({
      crossAxis: -192,
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

  describe('Impersonate', () => {
    describe('when not impersonating another user', () => {
      it('does not render the "Stop impersonation" button', () => {
        createWrapper(
          {},
          {},
          {
            isImpersonating: false,
            projectStudioEnabled: true,
          },
        );
        expect(findStopImpersonationButton().exists()).toBe(false);
      });
    });

    describe('when impersonating another user', () => {
      it('renders the "Stop impersonation" button', () => {
        createWrapper(
          {},
          {},
          {
            isImpersonating: true,
            projectStudioEnabled: true,
          },
        );
        expect(findStopImpersonationButton().exists()).toBe(true);
      });
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

    const setItem = ({
      can_update: canUpdate = false,
      busy = false,
      customized = false,
      stubs,
    } = {}) => {
      createWrapper(
        { status: { ...userMenuMockStatus, can_update: canUpdate, busy, customized } },
        stubs,
      );
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
        it('should pass the current status to the modal', async () => {
          createWrapper({
            status: { ...userMenuMockStatus, can_update: true, busy, customized },
          });

          wrapper.findByTestId('status-item').vm.$emit('action');
          await nextTick();

          expect(findSetStatusModal().exists()).toBe(true);
          expect(findSetStatusModal().props()).toMatchObject({
            defaultEmoji: 'speech_balloon',
            currentEmoji: userMenuMockStatus.emoji,
            currentMessage: userMenuMockStatus.message,
            currentAvailability: userMenuMockStatus.availability,
            currentClearStatusAfter: userMenuMockStatus.clear_after,
          });
        });

        it('casts falsey values to empty strings', async () => {
          createWrapper({
            status: { can_update: true, busy, customized },
          });

          wrapper.findByTestId('status-item').vm.$emit('action');
          await nextTick();

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
        it('should pass an empty status to the modal', async () => {
          createWrapper({
            status: { ...userMenuMockStatus, can_update: true, busy: false, customized: false },
          });

          wrapper.findByTestId('status-item').vm.$emit('action');
          await nextTick();

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

  describe('Buy compute minutes item', () => {
    /** @type {import('@vue/test-utils').Wrapper} */
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
          showDropdown();
          item.trigger('click');
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
        /** @type {MockAdapter} */
        let mockAxios;
        const dismissEndpoint = userMenuMockPipelineMinutes.callout_attrs.dismiss_endpoint;
        const featureName = userMenuMockPipelineMinutes.callout_attrs.feature_id;
        const href = userMenuMockPipelineMinutes.buy_pipeline_minutes_path;

        beforeEach(() => {
          mockAxios = new MockAdapter(axios);
        });

        afterEach(() => {
          mockAxios.restore();
        });

        describe('When `show_notification_dot` is `false`', () => {
          beforeEach(() => {
            setItem({ show_buy_pipeline_minutes: true, show_notification_dot: false });
          });

          it('does not render notification dot', () => {
            expect(wrapper.findByTestId('buy-pipeline-minutes-notification-dot').exists()).toBe(
              false,
            );
          });

          describe('clicking menu item', () => {
            beforeEach(() => {
              showDropdown();
              item.trigger('click');
            });

            it('does not call the callout dismiss endpoint', () => {
              expect(mockAxios.history.post).toHaveLength(0);
            });

            it('does not manually proceed to the URL', () => {
              expect(visitUrl).not.toHaveBeenCalled();
            });
          });
        });

        describe('When `show_notification_dot` is `true`', () => {
          beforeEach(() => {
            setItem({ show_buy_pipeline_minutes: true, show_notification_dot: true });
            showDropdown();
          });

          it('renders notification dot', () => {
            expect(wrapper.findByTestId('buy-pipeline-minutes-notification-dot').exists()).toBe(
              true,
            );
          });

          describe('clicking menu item', () => {
            describe('with successful callout dismissal', () => {
              beforeEach(async () => {
                mockAxios.onPost(dismissEndpoint).replyOnce(HTTP_STATUS_OK);
                item.trigger('click');
                await waitForPromises();
              });

              it('dismisses the callout', () => {
                expect(mockAxios.history.post[0].data).toBe(
                  JSON.stringify({ feature_name: featureName }),
                );
              });

              it('proceeds to the original URL', () => {
                expect(visitUrl).not.toHaveBeenCalledWith('abc');
              });
            });

            describe('with failed callout dismissal', () => {
              beforeEach(async () => {
                mockAxios.onPost(dismissEndpoint).replyOnce(HTTP_STATUS_INTERNAL_SERVER_ERROR);
                item.trigger('click');
                await waitForPromises();
              });

              it('reports the error to the Sentry', () => {
                expect(Sentry.captureException).toHaveBeenCalled();
              });

              it('reports the error to the console', () => {
                expect(logError).toHaveBeenCalled();
              });

              it('proceeds to the original URL', () => {
                expect(visitUrl).toHaveBeenCalledWith(href);
              });
            });
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

  describe('mobile user counts', () => {
    it('do not render when Project Studio is disabled', () => {
      createWrapper();
      expect(wrapper.findByTestId('user-counts-item').exists()).toBe(false);
    });

    it('should render with mobile-only CSS', () => {
      createWrapper({}, {}, { projectStudioEnabled: true });
      expect(wrapper.findByTestId('user-counts-item').classes()).toContain('md:gl-hidden');
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

  describe('Admin item', () => {
    const findAdminLinkItem = () => wrapper.findByTestId('admin-link');

    it.each`
      projectStudioEnabled | isAdmin  | adminModeFeatureEnabled | adminModeActive | isRendered
      ${false}             | ${false} | ${false}                | ${false}        | ${false}
      ${false}             | ${false} | ${false}                | ${true}         | ${false}
      ${false}             | ${false} | ${true}                 | ${false}        | ${false}
      ${false}             | ${false} | ${true}                 | ${true}         | ${false}
      ${false}             | ${true}  | ${false}                | ${false}        | ${false}
      ${false}             | ${true}  | ${false}                | ${true}         | ${false}
      ${false}             | ${true}  | ${true}                 | ${false}        | ${false}
      ${false}             | ${true}  | ${true}                 | ${true}         | ${false}
      ${true}              | ${false} | ${false}                | ${false}        | ${false}
      ${true}              | ${false} | ${false}                | ${true}         | ${false}
      ${true}              | ${false} | ${true}                 | ${false}        | ${false}
      ${true}              | ${false} | ${true}                 | ${true}         | ${false}
      ${true}              | ${true}  | ${false}                | ${false}        | ${true}
      ${true}              | ${true}  | ${false}                | ${true}         | ${true}
      ${true}              | ${true}  | ${true}                 | ${false}        | ${false}
      ${true}              | ${true}  | ${true}                 | ${true}         | ${true}
    `(
      'admin link item rendered is $isRendered when project studio is $projectStudioEnabled, isAdmin is $isAdmin, adminModeFeatureEnabled is $adminModeFeatureEnabled, and adminModeActive is $adminModeActive',
      ({ projectStudioEnabled, isAdmin, adminModeFeatureEnabled, adminModeActive, isRendered }) => {
        createWrapper(
          {
            admin_mode: {
              user_is_admin: isAdmin,
              admin_mode_feature_enabled: adminModeFeatureEnabled,
              admin_mode_active: adminModeActive,
            },
          },
          {},
          { projectStudioEnabled },
        );
        expect(findAdminLinkItem().exists()).toBe(isRendered);
      },
    );
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
