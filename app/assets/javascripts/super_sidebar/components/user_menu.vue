<script>
import {
  GlAvatar,
  GlBadge,
  GlDisclosureDropdown,
  GlDisclosureDropdownGroup,
  GlDisclosureDropdownItem,
} from '@gitlab/ui';
import SafeHtml from '~/vue_shared/directives/safe_html';
import { s__, __, sprintf } from '~/locale';
import NewNavToggle from '~/nav/components/new_nav_toggle.vue';
import Tracking from '~/tracking';
import PersistentUserCallout from '~/persistent_user_callout';
import UserNameGroup from './user_name_group.vue';

export default {
  feedbackUrl: 'https://gitlab.com/gitlab-org/gitlab/-/issues/new',
  i18n: {
    newNavigation: {
      badgeLabel: s__('NorthstarNavigation|Alpha'),
      sectionTitle: s__('NorthstarNavigation|Navigation redesign'),
    },
    setStatus: s__('SetStatusModal|Set status'),
    editStatus: s__('SetStatusModal|Edit status'),
    editProfile: s__('CurrentUser|Edit profile'),
    preferences: s__('CurrentUser|Preferences'),
    buyPipelineMinutes: s__('CurrentUser|Buy Pipeline minutes'),
    oneOfGroupsRunningOutOfPipelineMinutes: s__('CurrentUser|One of your groups is running out'),
    gitlabNext: s__('CurrentUser|Switch to GitLab Next'),
    provideFeedback: s__('NorthstarNavigation|Provide feedback'),
    startTrial: s__('CurrentUser|Start an Ultimate trial'),
    signOut: __('Sign out'),
  },
  components: {
    GlAvatar,
    GlBadge,
    GlDisclosureDropdown,
    GlDisclosureDropdownGroup,
    GlDisclosureDropdownItem,
    NewNavToggle,
    UserNameGroup,
  },
  directives: {
    SafeHtml,
  },
  mixins: [Tracking.mixin()],
  inject: ['toggleNewNavEndpoint'],
  props: {
    data: {
      required: true,
      type: Object,
    },
  },
  computed: {
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
          class: 'js-set-status-modal-trigger',
        },
      };
    },
    trialItem() {
      return {
        text: this.$options.i18n.startTrial,
        href: this.data.trial.url,
      };
    },
    editProfileItem() {
      return {
        text: this.$options.i18n.editProfile,
        href: this.data.settings.profile_path,
      };
    },
    preferencesItem() {
      return {
        text: this.$options.i18n.preferences,
        href: this.data.settings.profile_preferences_path,
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
        },
      };
    },
    gitlabNextItem() {
      return {
        text: this.$options.i18n.gitlabNext,
        href: this.data.canary_toggle_com_url,
      };
    },
    feedbackItem() {
      return {
        text: this.$options.i18n.provideFeedback,
        href: this.$options.feedbackUrl,
        extraAttrs: {
          target: '_blank',
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
              class: 'sign-out-link',
            },
          },
        ],
      };
    },
    statusModalData() {
      const defaultData = {
        'data-current-emoji': '',
        'data-current-message': '',
        'data-default-emoji': 'speech_balloon',
      };

      if (!this.data.status.customized) {
        return defaultData;
      }
      return {
        ...defaultData,
        'data-current-emoji': this.data.status.emoji,
        'data-current-message': this.data.status.message,
        'data-current-availability': this.data.status.availability,
        'data-current-clear-status-after': this.data.status.clear_after,
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
    showNotificationDot() {
      return this.data.pipeline_minutes?.show_notification_dot;
    },
  },
  methods: {
    onShow() {
      this.trackEvents();
      this.initCallout();
    },
    initCallout() {
      if (this.showNotificationDot) {
        PersistentUserCallout.factory(this.$refs?.buyPipelineMinutesNotificationCallout.$el);
      }
    },
    trackEvents() {
      if (this.addBuyPipelineMinutesMenuItem) {
        const {
          'track-action': trackAction,
          'track-label': label,
          'track-property': property,
        } = this.data.pipeline_minutes.tracking_attrs;
        this.track(trackAction, { label, property });
      }
    },
  },
};
</script>

<template>
  <div>
    <gl-disclosure-dropdown
      placement="right"
      data-testid="user-dropdown"
      data-qa-selector="user_menu"
      @shown="onShow"
    >
      <template #toggle>
        <button class="user-bar-item btn-with-notification">
          <span class="gl-sr-only">{{ toggleText }}</span>
          <gl-avatar
            :size="24"
            :entity-name="data.name"
            :src="data.avatar_url"
            aria-hidden="true"
            data-qa-selector="user_avatar_content"
          />
          <span
            v-if="showNotificationDot"
            class="notification-dot-warning"
            data-testid="buy-pipeline-minutes-notification-dot"
            v-bind="data.pipeline_minutes.notification_dot_attrs"
          >
          </span>
        </button>
      </template>

      <user-name-group :user="data" />
      <gl-disclosure-dropdown-group bordered>
        <gl-disclosure-dropdown-item
          v-if="data.status.can_update"
          :item="statusItem"
          data-testid="status-item"
        />

        <gl-disclosure-dropdown-item
          v-if="data.trial.has_start_trial"
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
        >
          <template #list-item>
            <span class="gl-display-flex gl-flex-direction-column">
              <span>{{ buyPipelineMinutesItem.text }} <gl-emoji data-name="clock9" /></span>
              <span
                v-if="data.pipeline_minutes.show_with_subtext"
                class="gl-font-sm small gl-pt-2 gl-text-orange-800"
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
      </gl-disclosure-dropdown-group>

      <gl-disclosure-dropdown-group bordered>
        <template #group-label>
          <span class="gl-font-sm">{{ $options.i18n.newNavigation.sectionTitle }}</span>
          <gl-badge size="sm" variant="info"
            >{{ $options.i18n.newNavigation.badgeLabel }}
          </gl-badge>
        </template>
        <new-nav-toggle :endpoint="toggleNewNavEndpoint" enabled new-navigation />
        <gl-disclosure-dropdown-item :item="feedbackItem" data-testid="feedback-item" />
      </gl-disclosure-dropdown-group>

      <gl-disclosure-dropdown-group
        v-if="data.can_sign_out"
        bordered
        :group="signOutGroup"
        data-testid="sign-out-group"
      />
    </gl-disclosure-dropdown>

    <div
      v-if="data.status.can_update"
      class="js-set-status-modal-wrapper"
      v-bind="statusModalData"
    ></div>
  </div>
</template>
