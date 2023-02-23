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
import UserNameGroup from './user_name_group.vue';

export default {
  feedbackUrl: 'https://gitlab.com/gitlab-org/gitlab/-/issues/new',
  i18n: {
    newNavigation: {
      badgeLabel: s__('NorthstarNavigation|Alpha'),
      sectionTitle: s__('NorthstarNavigation|Navigation redesign'),
    },
    user: {
      setStatus: s__('SetStatusModal|Set status'),
      editStatus: s__('SetStatusModal|Edit status'),
      editProfile: s__('CurrentUser|Edit profile'),
      preferences: s__('CurrentUser|Preferences'),
      gitlabNext: s__('CurrentUser|Switch to GitLab Next'),
    },
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
        busy || customized ? this.$options.i18n.user.editStatus : this.$options.i18n.user.setStatus;

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
        text: this.$options.i18n.user.editProfile,
        href: this.data.settings.profile_path,
      };
    },
    preferencesItem() {
      return {
        text: this.$options.i18n.user.preferences,
        href: this.data.settings.profile_preferences_path,
      };
    },
    gitlabNextItem() {
      return {
        text: this.$options.i18n.user.gitlabNext,
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
  },
};
</script>

<template>
  <div>
    <gl-disclosure-dropdown
      placement="right"
      data-testid="user-dropdown"
      data-qa-selector="user_menu"
    >
      <template #toggle>
        <button class="user-bar-item">
          <span class="gl-sr-only">{{ toggleText }}</span>
          <gl-avatar
            :size="24"
            :entity-name="data.name"
            :src="data.avatar_url"
            aria-hidden="true"
            data-qa-selector="user_avatar_content"
          />
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
