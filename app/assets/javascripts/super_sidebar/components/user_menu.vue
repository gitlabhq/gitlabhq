<script>
import {
  GlAvatar,
  GlIcon,
  GlDisclosureDropdown,
  GlDisclosureDropdownGroup,
  GlDisclosureDropdownItem,
  GlButton,
  GlModalDirective,
  GlTooltipDirective,
} from '@gitlab/ui';
import SafeHtml from '~/vue_shared/directives/safe_html';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import DapWelcomeModal from '~/dap_welcome_modal/dap_welcome_modal.vue';
import { s__, __, sprintf } from '~/locale';
import Tracking from '~/tracking';
import { SET_STATUS_MODAL_ID } from '~/set_status_modal/constants';
import axios from '~/lib/utils/axios_utils';
import { visitUrl } from '~/lib/utils/url_utility';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import { logError } from '~/lib/logger';
import { USER_MENU_TRACKING_DEFAULTS, DROPDOWN_Y_OFFSET } from '../constants';
import UserMenuProfileItem from './user_menu_profile_item.vue';
import UserMenuProjectStudioSection from './user_menu_project_studio_section.vue';
import UserCounts from './user_counts.vue';

// Left offset required for the dropdown to be aligned with the super sidebar
const DROPDOWN_X_OFFSET_BASE = -192;

export default {
  SET_STATUS_MODAL_ID,
  i18n: {
    setStatus: s__('SetStatusModal|Set status'),
    editStatus: s__('SetStatusModal|Edit status'),
    editProfile: s__('CurrentUser|Edit profile'),
    preferences: s__('CurrentUser|Preferences'),
    buyPipelineMinutes: s__('CurrentUser|Buy compute minutes'),
    oneOfGroupsRunningOutOfPipelineMinutes: s__('CurrentUser|One of your groups is running out'),
    gitlabNext: s__('CurrentUser|Switch to GitLab Next'),
    startTrial: s__('CurrentUser|Start an Ultimate trial'),
    adminArea: s__('Navigation|Admin'),
    enterAdminMode: s__('CurrentUser|Enter Admin Mode'),
    leaveAdminMode: s__('CurrentUser|Leave Admin Mode'),
    stopImpersonating: __('Stop impersonating'),
    signOut: __('Sign out'),
  },
  components: {
    GlAvatar,
    GlIcon,
    GlDisclosureDropdown,
    GlDisclosureDropdownGroup,
    GlDisclosureDropdownItem,
    GlButton,
    UserCounts,
    UserMenuProfileItem,
    UserMenuProjectStudioSection,
    DapWelcomeModal,
    SetStatusModal: () =>
      import(
        /* webpackChunkName: 'statusModalBundle' */ '~/set_status_modal/set_status_modal_wrapper.vue'
      ),
  },
  directives: {
    SafeHtml,
    GlModal: GlModalDirective,
    GlTooltip: GlTooltipDirective,
  },
  mixins: [Tracking.mixin(), glFeatureFlagsMixin()],
  inject: ['isImpersonating', 'projectStudioAvailable', 'projectStudioEnabled'],
  props: {
    data: {
      required: true,
      type: Object,
    },
  },
  data() {
    return {
      setStatusModalReady: false,
      showDapWelcomeModal: false,
      updatedAvatarUrl: null,
    };
  },
  computed: {
    avatarUrl() {
      return this.updatedAvatarUrl || this.data.avatar_url;
    },
    toggleText() {
      return sprintf(__('%{user} user’s menu'), { user: this.data.name });
    },
    isAdmin() {
      return this.data?.admin_mode?.user_is_admin;
    },
    adminLinkItem() {
      return {
        text: this.$options.i18n.adminArea,
        href: this.data.admin_url,
      };
    },
    statusLabel() {
      const { busy, customized } = this.data.status;
      return busy || customized ? this.$options.i18n.editStatus : this.$options.i18n.setStatus;
    },
    statusItem() {
      return {
        text: this.statusLabel,
        extraAttrs: {
          ...USER_MENU_TRACKING_DEFAULTS,
          'data-track-label': 'user_edit_status',
        },
      };
    },
    trialItem() {
      return {
        text: this.$options.i18n.startTrial,
        href: this.data.trial.url,
        extraAttrs: {
          ...USER_MENU_TRACKING_DEFAULTS,
          'data-track-label': 'start_trial',
        },
      };
    },
    showTrialItem() {
      return this.data.trial?.has_start_trial;
    },
    editProfileItem() {
      return {
        text: this.$options.i18n.editProfile,
        href: this.data.settings.profile_path,
        extraAttrs: {
          'data-testid': 'edit-profile-link',
          ...USER_MENU_TRACKING_DEFAULTS,
          'data-track-label': 'user_edit_profile',
        },
      };
    },
    preferencesItem() {
      return {
        text: this.$options.i18n.preferences,
        href: this.data.settings.profile_preferences_path,
        extraAttrs: {
          ...USER_MENU_TRACKING_DEFAULTS,
          'data-track-label': 'user_preferences',
        },
      };
    },
    addBuyPipelineMinutesMenuItem() {
      return this.data.pipeline_minutes?.show_buy_pipeline_minutes;
    },
    buyPipelineMinutesItem() {
      return {
        text: this.$options.i18n.buyPipelineMinutes,
        warningText: this.$options.i18n.oneOfGroupsRunningOutOfPipelineMinutes,
        href: this.data.pipeline_minutes?.buy_pipeline_minutes_path,
        extraAttrs: {
          ...USER_MENU_TRACKING_DEFAULTS,
          'data-track-label': 'buy_pipeline_minutes',
        },
      };
    },
    gitlabNextItem() {
      return {
        text: this.$options.i18n.gitlabNext,
        href: this.data.canary_toggle_com_url,
        extraAttrs: {
          ...USER_MENU_TRACKING_DEFAULTS,
          'data-track-label': 'switch_to_canary',
        },
      };
    },
    enterAdminModeItem() {
      return {
        text: this.$options.i18n.enterAdminMode,
        href: this.data.admin_mode.enter_admin_mode_url,
        extraAttrs: {
          ...USER_MENU_TRACKING_DEFAULTS,
          'data-track-label': 'enter_admin_mode',
        },
      };
    },
    leaveAdminModeItem() {
      return {
        text: this.$options.i18n.leaveAdminMode,
        href: this.data.admin_mode.leave_admin_mode_url,
        extraAttrs: {
          ...USER_MENU_TRACKING_DEFAULTS,
          'data-track-label': 'leave_admin_mode',
          'data-method': 'post',
        },
      };
    },
    signOutItem() {
      return {
        text: this.$options.i18n.signOut,
        href: this.data.sign_out_link,
        extraAttrs: {
          'data-method': 'post',
          'data-testid': 'sign-out-link',
          class: 'sign-out-link',
        },
      };
    },
    statusModalData() {
      if (!this.data?.status?.can_update) {
        return null;
      }

      const { busy, customized } = this.data.status;

      if (!busy && !customized) {
        return {};
      }
      const { emoji, message, availability, clear_after: clearAfter } = this.data.status;

      return {
        'current-emoji': emoji || '',
        'current-message': message || '',
        'current-availability': availability || '',
        'current-clear-status-after': clearAfter || '',
      };
    },
    showAdminButton() {
      return (
        this.isAdmin &&
        (!this.data.admin_mode.admin_mode_feature_enabled || this.data.admin_mode.admin_mode_active)
      );
    },
    showEnterAdminModeItem() {
      return (
        this.data.admin_mode.user_is_admin &&
        this.data.admin_mode.admin_mode_feature_enabled &&
        !this.data.admin_mode.admin_mode_active
      );
    },
    showLeaveAdminModeItem() {
      return (
        this.data.admin_mode.user_is_admin &&
        this.data.admin_mode.admin_mode_feature_enabled &&
        this.data.admin_mode.admin_mode_active
      );
    },
    showNotificationDot() {
      return this.data.pipeline_minutes?.show_notification_dot;
    },
    dropdownOffset() {
      return {
        mainAxis: DROPDOWN_Y_OFFSET,
        crossAxis: DROPDOWN_X_OFFSET_BASE,
      };
    },
    hasEmoji() {
      return this.data?.status?.emoji;
    },
  },
  mounted() {
    document.addEventListener('userAvatar:update', this.updateAvatar);
    this.showDapWelcomeModal = localStorage.getItem('showDapWelcomeModal') === 'true';
  },
  unmounted() {
    document.removeEventListener('userAvatar:update', this.updateAvatar);
  },
  methods: {
    updateAvatar(event) {
      this.updatedAvatarUrl = event.detail?.url;
    },
    onShow() {
      this.initBuyCIMinsCallout();
    },
    openStatusModal() {
      this.setStatusModalReady = true;
      this.$refs.userDropdown.close();
    },
    closeDapWelcomeModal() {
      localStorage.removeItem('showDapWelcomeModal');
    },
    initBuyCIMinsCallout() {
      const el = this.$refs?.buyPipelineMinutesNotificationCallout?.$el;
      el?.addEventListener('click', this.onBuyCIMinutesItemClick);
    },
    async onBuyCIMinutesItemClick(event) {
      /* NOTE: We're not sure this event is tracked by anyone
       * whether it stays will depend on the outcome of this discussion:
       * https://gitlab.com/gitlab-org/gitlab/-/issues/402713#note_1343072135
       */
      const {
        'track-action': trackAction,
        'track-label': label,
        'track-property': property,
      } = this.data.pipeline_minutes.tracking_attrs;
      this.track(trackAction, { label, property });

      // Proceed to the URL if the notification dot is not shown
      if (!this.showNotificationDot) return;

      event.preventDefault();
      const href = this.data.pipeline_minutes?.buy_pipeline_minutes_path;
      const featureId = this.data.pipeline_minutes.callout_attrs.feature_id;
      const dismissEndpoint = this.data.pipeline_minutes.callout_attrs.dismiss_endpoint;

      try {
        // dismiss the notification dot Callout
        await axios.post(dismissEndpoint, { feature_name: featureId });
      } catch (error) {
        logError(error);
        Sentry.captureException(error);
      } finally {
        // visit the URL whether the callout notification is dismissed or not
        visitUrl(href);
      }
    },
    trackSignOut() {
      this.track(USER_MENU_TRACKING_DEFAULTS['data-track-action'], {
        label: 'user_sign_out',
        property: USER_MENU_TRACKING_DEFAULTS['data-track-property'],
      });
    },
  },
};
</script>

<template>
  <div
    :class="{
      'gl-flex gl-rounded-[1rem] gl-bg-neutral-800 dark:gl-bg-neutral-50': projectStudioEnabled,
    }"
  >
    <gl-button
      v-if="projectStudioEnabled && isImpersonating"
      v-gl-tooltip.bottom
      :href="data.stop_impersonation_path"
      :title="$options.i18n.stopImpersonating"
      :aria-label="$options.i18n.stopImpersonating"
      icon="incognito"
      class="-gl-mr-4 !gl-rounded-l-[1rem] !gl-rounded-r-none !gl-pl-3 !gl-pr-5 !gl-text-neutral-0 dark:!gl-text-neutral-800"
      category="tertiary"
      data-method="delete"
      data-testid="stop-impersonation-btn"
    />

    <gl-disclosure-dropdown
      ref="userDropdown"
      :dropdown-offset="dropdownOffset"
      class="super-sidebar-user-dropdown gl-relative"
      data-testid="user-dropdown"
      :auto-close="false"
      @shown="onShow"
    >
      <template #toggle>
        <gl-button
          category="tertiary"
          class="user-bar-dropdown-toggle btn-with-notification"
          :class="{ '!gl-rounded-full !gl-border-none !gl-px-0': projectStudioEnabled }"
          data-testid="user-menu-toggle"
          data-track-action="click_dropdown"
          data-track-label="user_profile_menu"
          data-track-property="nav_core_menu"
        >
          <span class="gl-sr-only">{{ toggleText }}</span>
          <gl-avatar
            :size="projectStudioEnabled ? 32 : 24"
            :entity-name="data.name"
            :src="avatarUrl"
            aria-hidden="true"
            data-testid="user-avatar-content"
          />
          <span
            v-if="showNotificationDot"
            class="notification-dot-warning"
            data-testid="buy-pipeline-minutes-notification-dot"
            v-bind="data.pipeline_minutes.notification_dot_attrs"
          >
          </span>
        </gl-button>

        <div
          v-if="projectStudioEnabled && hasEmoji"
          class="gl-absolute -gl-bottom-1 -gl-right-1 gl-flex gl-h-5 gl-w-5 gl-cursor-pointer gl-items-center gl-justify-center gl-rounded-full gl-bg-neutral-0 gl-text-sm gl-shadow-sm"
          :title="data.status.message"
        >
          <gl-emoji
            :data-name="data.status.emoji"
            class="super-topbar-status-emoji gl-pointer-events-none gl-text-[9px]"
          />
        </div>
      </template>

      <gl-disclosure-dropdown-group>
        <user-menu-profile-item :user="data" />
      </gl-disclosure-dropdown-group>

      <gl-disclosure-dropdown-item
        v-if="projectStudioEnabled"
        class="gl-border-t gl-flex gl-pt-2 md:gl-hidden"
        data-testid="user-counts-item"
      >
        <user-counts
          :sidebar-data="data"
          class="gl-w-full"
          counter-class="gl-button btn btn-default btn-default-tertiary"
        />
      </gl-disclosure-dropdown-item>

      <gl-disclosure-dropdown-group bordered>
        <gl-disclosure-dropdown-item
          v-if="statusModalData"
          v-gl-modal="$options.SET_STATUS_MODAL_ID"
          :item="statusItem"
          data-testid="status-item"
          @action="openStatusModal"
        >
          <template #list-item>
            <gl-icon name="slight-smile" variant="subtle" class="gl-mr-2" />
            <span>{{ statusLabel }}</span>
          </template>
        </gl-disclosure-dropdown-item>

        <gl-disclosure-dropdown-item :item="editProfileItem" data-testid="edit-profile-item">
          <template #list-item>
            <gl-icon name="profile" variant="subtle" class="gl-mr-2" />
            <span>{{ $options.i18n.editProfile }}</span>
          </template>
        </gl-disclosure-dropdown-item>

        <gl-disclosure-dropdown-item :item="preferencesItem" data-testid="preferences-item">
          <template #list-item>
            <gl-icon name="preferences" variant="subtle" class="gl-mr-2" />
            <span>{{ $options.i18n.preferences }}</span>
          </template>
        </gl-disclosure-dropdown-item>

        <gl-disclosure-dropdown-item
          v-if="projectStudioEnabled && showAdminButton"
          :item="adminLinkItem"
          class="xl:gl-hidden"
          data-testid="admin-link"
        >
          <template #list-item>
            <gl-icon name="admin" variant="subtle" class="gl-mr-2" />
            <span>{{ $options.i18n.adminArea }}</span>
          </template>
        </gl-disclosure-dropdown-item>

        <gl-disclosure-dropdown-item
          v-if="showEnterAdminModeItem"
          :item="enterAdminModeItem"
          data-testid="enter-admin-mode-item"
        >
          <template #list-item>
            <gl-icon name="lock" variant="subtle" class="gl-mr-2" />
            <span>{{ $options.i18n.enterAdminMode }}</span>
          </template>
        </gl-disclosure-dropdown-item>
        <gl-disclosure-dropdown-item
          v-if="showLeaveAdminModeItem"
          :item="leaveAdminModeItem"
          data-testid="leave-admin-mode-item"
        >
          <template #list-item>
            <gl-icon name="lock-open" variant="subtle" class="gl-mr-2" />
            <span>{{ $options.i18n.leaveAdminMode }}</span>
          </template>
        </gl-disclosure-dropdown-item>
      </gl-disclosure-dropdown-group>

      <gl-disclosure-dropdown-group v-if="showTrialItem || addBuyPipelineMinutesMenuItem" bordered>
        <gl-disclosure-dropdown-item
          v-if="showTrialItem"
          :item="trialItem"
          data-testid="start-trial-item"
        >
          <template #list-item>
            <span class="hotspot-pulse gl-flex gl-items-center gl-gap-2">
              <gl-icon name="license" variant="subtle" class="gl-mr-2" />
              {{ trialItem.text }}
            </span>
          </template>
        </gl-disclosure-dropdown-item>

        <gl-disclosure-dropdown-item
          v-if="addBuyPipelineMinutesMenuItem"
          ref="buyPipelineMinutesNotificationCallout"
          :item="buyPipelineMinutesItem"
          data-testid="buy-pipeline-minutes-item"
        >
          <template #list-item>
            <gl-icon name="credit-card" variant="subtle" class="gl-mr-2" />
            <span>{{ buyPipelineMinutesItem.text }}</span>
            <span
              v-if="data.pipeline_minutes.show_with_subtext"
              class="gl-block gl-pt-2 gl-text-sm gl-text-warning"
              >{{ buyPipelineMinutesItem.warningText }}</span
            >
          </template>
        </gl-disclosure-dropdown-item>
      </gl-disclosure-dropdown-group>

      <user-menu-project-studio-section v-if="projectStudioAvailable" />

      <gl-disclosure-dropdown-group v-if="data.gitlab_com_but_not_canary" bordered>
        <gl-disclosure-dropdown-item :item="gitlabNextItem" data-testid="gitlab-next-item">
          <template #list-item>
            <gl-icon name="trigger-source" variant="subtle" class="gl-mr-2" />
            <span>{{ $options.i18n.gitlabNext }}</span>
          </template>
        </gl-disclosure-dropdown-item>
      </gl-disclosure-dropdown-group>

      <gl-disclosure-dropdown-group
        v-if="data.can_sign_out"
        bordered
        data-testid="sign-out-group"
        @action="trackSignOut"
      >
        <gl-disclosure-dropdown-item :item="signOutItem">
          <template #list-item>
            <gl-icon name="power" variant="subtle" class="gl-mr-2" />
            <span>{{ $options.i18n.signOut }}</span>
          </template>
        </gl-disclosure-dropdown-item>
      </gl-disclosure-dropdown-group>
    </gl-disclosure-dropdown>
    <set-status-modal
      v-if="setStatusModalReady"
      default-emoji="speech_balloon"
      v-bind="statusModalData"
    />
    <dap-welcome-modal v-if="showDapWelcomeModal" @close="closeDapWelcomeModal" />
  </div>
</template>
