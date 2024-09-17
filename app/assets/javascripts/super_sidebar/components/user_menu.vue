<script>
import {
  GlAvatar,
  GlDisclosureDropdown,
  GlDisclosureDropdownGroup,
  GlDisclosureDropdownItem,
  GlButton,
  GlModalDirective,
} from '@gitlab/ui';
import SafeHtml from '~/vue_shared/directives/safe_html';
import { s__, __, sprintf } from '~/locale';
import Tracking from '~/tracking';
import PersistentUserCallout from '~/persistent_user_callout';
import { SET_STATUS_MODAL_ID } from '~/set_status_modal/constants';
import { USER_MENU_TRACKING_DEFAULTS, DROPDOWN_Y_OFFSET, IMPERSONATING_OFFSET } from '../constants';
import UserMenuProfileItem from './user_menu_profile_item.vue';

// Left offset required for the dropdown to be aligned with the super sidebar
const DROPDOWN_X_OFFSET_BASE = -211;
const DROPDOWN_X_OFFSET_IMPERSONATING = DROPDOWN_X_OFFSET_BASE + IMPERSONATING_OFFSET;

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
    enterAdminMode: s__('CurrentUser|Enter Admin Mode'),
    leaveAdminMode: s__('CurrentUser|Leave Admin Mode'),
    signOut: __('Sign out'),
  },
  components: {
    GlAvatar,
    GlDisclosureDropdown,
    GlDisclosureDropdownGroup,
    GlDisclosureDropdownItem,
    GlButton,
    UserMenuProfileItem,
    SetStatusModal: () =>
      import(
        /* webpackChunkName: 'statusModalBundle' */ '~/set_status_modal/set_status_modal_wrapper.vue'
      ),
  },
  directives: {
    SafeHtml,
    GlModal: GlModalDirective,
  },
  mixins: [Tracking.mixin()],
  inject: ['isImpersonating'],
  props: {
    data: {
      required: true,
      type: Object,
    },
  },
  data() {
    return {
      setStatusModalReady: false,
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
    statusItem() {
      const { busy, customized } = this.data.status;

      const statusLabel =
        busy || customized ? this.$options.i18n.editStatus : this.$options.i18n.setStatus;

      return {
        text: statusLabel,
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
          class: 'js-follow-link',
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
    signOutGroup() {
      return {
        items: [
          {
            text: this.$options.i18n.signOut,
            href: this.data.sign_out_link,
            extraAttrs: {
              'data-method': 'post',
              'data-testid': 'sign-out-link',
              class: 'sign-out-link',
            },
          },
        ],
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
    buyPipelineMinutesCalloutData() {
      return this.showNotificationDot
        ? {
            'data-feature-id': this.data.pipeline_minutes.callout_attrs.feature_id,
            'data-dismiss-endpoint': this.data.pipeline_minutes.callout_attrs.dismiss_endpoint,
          }
        : {};
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
        crossAxis: this.isImpersonating ? DROPDOWN_X_OFFSET_IMPERSONATING : DROPDOWN_X_OFFSET_BASE,
      };
    },
  },
  mounted() {
    document.addEventListener('userAvatar:update', this.updateAvatar);
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
    closeDropdown() {
      this.$refs.userDropdown.close();
    },
    initBuyCIMinsCallout() {
      if (this.showNotificationDot) {
        PersistentUserCallout.factory(this.$refs?.buyPipelineMinutesNotificationCallout.$el);
      }
    },
    /* We're not sure this event is tracked by anyone
      whether it stays will depend on the outcome of this discussion:
      https://gitlab.com/gitlab-org/gitlab/-/issues/402713#note_1343072135 */
    trackBuyCIMins() {
      if (this.addBuyPipelineMinutesMenuItem) {
        const {
          'track-action': trackAction,
          'track-label': label,
          'track-property': property,
        } = this.data.pipeline_minutes.tracking_attrs;
        this.track(trackAction, { label, property });
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
  <div>
    <gl-disclosure-dropdown
      ref="userDropdown"
      :dropdown-offset="dropdownOffset"
      data-testid="user-dropdown"
      :auto-close="false"
      @shown="onShow"
    >
      <template #toggle>
        <gl-button
          category="tertiary"
          class="user-bar-dropdown-toggle btn-with-notification"
          data-testid="user-menu-toggle"
        >
          <span class="gl-sr-only">{{ toggleText }}</span>
          <gl-avatar
            :size="24"
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
      </template>

      <gl-disclosure-dropdown-group>
        <user-menu-profile-item :user="data" />
      </gl-disclosure-dropdown-group>

      <gl-disclosure-dropdown-group bordered>
        <gl-disclosure-dropdown-item
          v-if="setStatusModalReady && statusModalData"
          v-gl-modal="$options.SET_STATUS_MODAL_ID"
          :item="statusItem"
          data-testid="status-item"
          @action="closeDropdown"
        />

        <gl-disclosure-dropdown-item
          v-if="showTrialItem"
          :item="trialItem"
          data-testid="start-trial-item"
        >
          <template #list-item>
            {{ trialItem.text }}
            <gl-emoji data-name="rocket" />
          </template>
        </gl-disclosure-dropdown-item>

        <gl-disclosure-dropdown-item :item="editProfileItem" data-testid="edit-profile-item" />

        <gl-disclosure-dropdown-item :item="preferencesItem" data-testid="preferences-item" />

        <gl-disclosure-dropdown-item
          v-if="addBuyPipelineMinutesMenuItem"
          ref="buyPipelineMinutesNotificationCallout"
          :item="buyPipelineMinutesItem"
          v-bind="buyPipelineMinutesCalloutData"
          data-testid="buy-pipeline-minutes-item"
          @action="trackBuyCIMins"
        >
          <template #list-item>
            <span class="gl-flex gl-flex-col">
              <span>{{ buyPipelineMinutesItem.text }} <gl-emoji data-name="clock9" /></span>
              <span
                v-if="data.pipeline_minutes.show_with_subtext"
                class="small gl-pt-2 gl-text-sm gl-text-orange-800"
                >{{ buyPipelineMinutesItem.warningText }}</span
              >
            </span>
          </template>
        </gl-disclosure-dropdown-item>

        <gl-disclosure-dropdown-item
          v-if="data.gitlab_com_but_not_canary"
          :item="gitlabNextItem"
          data-testid="gitlab-next-item"
        />

        <gl-disclosure-dropdown-item
          v-if="showEnterAdminModeItem"
          :item="enterAdminModeItem"
          data-testid="enter-admin-mode-item"
        />
        <gl-disclosure-dropdown-item
          v-if="showLeaveAdminModeItem"
          :item="leaveAdminModeItem"
          data-testid="leave-admin-mode-item"
        />
      </gl-disclosure-dropdown-group>

      <gl-disclosure-dropdown-group
        v-if="data.can_sign_out"
        bordered
        :group="signOutGroup"
        data-testid="sign-out-group"
        @action="trackSignOut"
      />
    </gl-disclosure-dropdown>
    <set-status-modal
      v-if="statusModalData"
      default-emoji="speech_balloon"
      v-bind="statusModalData"
      @mounted="setStatusModalReady = true"
    />
  </div>
</template>
