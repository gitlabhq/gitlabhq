<script>
import {
  GlBadge,
  GlPopover,
  GlLink,
  GlSkeletonLoader,
  GlIcon,
  GlSprintf,
  GlButton,
  GlAvatarLabeled,
} from '@gitlab/ui';
import SafeHtml from '~/vue_shared/directives/safe_html';
import { glEmojiTag } from '~/emoji';
import { createAlert } from '~/alert';
import { followUser, unfollowUser } from '~/rest_api';
import { isUserBusy } from '~/set_status_modal/utils';
import Tracking from '~/tracking';
import HelpIcon from '~/vue_shared/components/help_icon/help_icon.vue';
import {
  I18N_ERROR_FOLLOW,
  I18N_ERROR_UNFOLLOW,
  I18N_USER_BLOCKED,
  I18N_USER_BUSY,
  I18N_USER_LEARN,
  I18N_USER_FOLLOW,
  I18N_USER_UNFOLLOW,
  USER_POPOVER_DELAY,
} from './constants';

const MAX_SKELETON_LINES = 4;

export default {
  name: 'UserPopover',
  maxSkeletonLines: MAX_SKELETON_LINES,
  I18N_USER_BLOCKED,
  I18N_USER_BUSY,
  I18N_USER_LEARN,
  USER_POPOVER_DELAY,
  components: {
    GlBadge,
    GlIcon,
    GlLink,
    GlPopover,
    GlSkeletonLoader,
    GlSprintf,
    GlButton,
    GlAvatarLabeled,
    HelpIcon,
  },
  directives: {
    SafeHtml,
  },
  mixins: [Tracking.mixin()],
  props: {
    target: {
      type: HTMLElement,
      required: true,
    },
    user: {
      type: Object,
      required: true,
      default: null,
    },
    placement: {
      type: String,
      required: false,
      default: 'top',
    },
    show: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  data() {
    return {
      toggleFollowLoading: false,
    };
  },
  computed: {
    statusHtml() {
      if (!this.user.status) {
        return '';
      }

      if (this.user.status.emoji && this.user.status.message_html) {
        return `${glEmojiTag(this.user.status.emoji)} ${this.user.status.message_html}`;
      }
      if (this.user.status.message_html) {
        return this.user.status.message_html;
      }
      if (this.user.status.emoji) {
        return glEmojiTag(this.user.status.emoji);
      }

      return '';
    },
    userCannotMerge() {
      return this.target.dataset.cannotMerge;
    },
    userIsLoading() {
      return !this.user?.loaded;
    },
    availabilityStatus() {
      return this.user?.status?.availability || '';
    },
    isNotCurrentUser() {
      return !this.userIsLoading && this.user.username !== gon.current_username;
    },
    shouldRenderToggleFollowButton() {
      return this.isNotCurrentUser && typeof this.user?.isFollowed !== 'undefined';
    },
    toggleFollowButtonText() {
      if (this.toggleFollowLoading) return null;

      return this.user?.isFollowed ? I18N_USER_UNFOLLOW : I18N_USER_FOLLOW;
    },
    toggleFollowButtonVariant() {
      return this.user?.isFollowed ? 'default' : 'confirm';
    },
    hasPronouns() {
      return Boolean(this.user?.pronouns?.trim());
    },
    isBlocked() {
      return this.user?.state === 'blocked';
    },
    isBusy() {
      return isUserBusy(this.availabilityStatus);
    },
    username() {
      return `@${this.user?.username}`;
    },
    cssClasses() {
      const classList = ['user-popover', 'gl-max-w-48', 'gl-overflow-hidden'];

      if (this.userCannotMerge) {
        classList.push('user-popover-cannot-merge');
      }

      return classList;
    },
  },
  methods: {
    async toggleFollow() {
      if (this.user.isFollowed) {
        this.unfollow();
      } else {
        this.follow();
      }
    },
    async follow() {
      this.toggleFollowLoading = true;

      this.track('click_button', {
        label: 'follow_from_user_popover',
      });

      try {
        await followUser(this.user.id);
        this.$emit('follow');
      } catch (error) {
        const message = error.response?.data?.message || I18N_ERROR_FOLLOW;
        createAlert({
          message,
          error,
          captureError: true,
        });
      } finally {
        this.toggleFollowLoading = false;
      }
    },
    async unfollow() {
      this.toggleFollowLoading = true;

      this.track('click_button', {
        label: 'unfollow_from_user_popover',
      });

      try {
        await unfollowUser(this.user.id);
        this.$emit('unfollow');
      } catch (error) {
        createAlert({
          message: I18N_ERROR_UNFOLLOW,
          error,
          captureError: true,
        });
      } finally {
        this.toggleFollowLoading = false;
      }
    },
  },
  safeHtmlConfig: { ADD_TAGS: ['gl-emoji'] },
};
</script>

<template>
  <!-- Delayed so not every mouseover triggers Popover -->
  <gl-popover
    :css-classes="cssClasses"
    :show="show"
    :target="target"
    :delay="$options.USER_POPOVER_DELAY"
    :placement="placement"
    boundary="viewport"
    triggers="hover focus manual"
    data-testid="user-popover"
  >
    <template v-if="userCannotMerge" #title>
      <div class="gl-flex gl-items-center gl-pb-3" data-testid="cannot-merge">
        <gl-icon name="warning-solid" class="gl-mr-2" variant="warning" />
        <span class="gl-font-normal">{{ __('Cannot merge') }}</span>
      </div>
    </template>
    <div class="gl-mb-3">
      <div v-if="userIsLoading" class="gl-w-20">
        <gl-skeleton-loader :width="160" :height="64">
          <rect x="70" y="19" rx="3" ry="3" width="88" height="9" />
          <rect x="70" y="36" rx="3" ry="3" width="64" height="8" />
          <circle cx="32" cy="32" r="32" />
        </gl-skeleton-loader>
      </div>
      <gl-avatar-labeled
        v-else
        :size="64"
        :src="user.avatarUrl"
        :label="user.name"
        :sub-label="username"
        class="gl-w-full"
      >
        <template v-if="isBlocked">
          <span class="gl-mt-4 gl-italic">{{ $options.I18N_USER_BLOCKED }}</span>
        </template>
        <template v-else>
          <gl-button
            v-if="shouldRenderToggleFollowButton"
            class="gl-mt-3 gl-self-start"
            :variant="toggleFollowButtonVariant"
            :loading="toggleFollowLoading"
            size="small"
            data-testid="toggle-follow-button"
            @click="toggleFollow"
            >{{ toggleFollowButtonText }}</gl-button
          >
        </template>

        <template #meta>
          <span
            v-if="hasPronouns"
            class="gl-p-1 gl-text-sm gl-font-normal gl-text-subtle"
            data-testid="user-popover-pronouns"
            >({{ user.pronouns }})</span
          >
          <gl-badge v-if="isBusy" variant="warning" class="gl-ml-1">
            {{ $options.I18N_USER_BUSY }}
          </gl-badge>
        </template>
      </gl-avatar-labeled>
    </div>
    <div class="gl-mt-2 gl-w-full gl-break-anywhere">
      <template v-if="userIsLoading">
        <gl-skeleton-loader
          :lines="$options.maxSkeletonLines"
          preserve-aspect-ratio="none"
          equal-width-lines
          :height="24"
        />
      </template>
      <template v-else>
        <template v-if="!isBlocked">
          <div class="gl-text-subtle">
            <div v-if="user.email" class="gl-mb-2 gl-flex">
              <gl-icon name="mail" class="gl-shrink-0" />
              <span ref="email" class="gl-ml-2">{{ user.email }}</span>
            </div>
            <div v-if="user.bio" class="gl-mb-2 gl-flex">
              <gl-icon name="profile" class="gl-shrink-0" />
              <span ref="bio" class="gl-ml-2">{{ user.bio }}</span>
            </div>
            <div v-if="user.workInformation" class="gl-mb-2 gl-flex">
              <gl-icon name="work" class="gl-shrink-0" />
              <span ref="workInformation" class="gl-ml-2">{{ user.workInformation }}</span>
            </div>
            <div v-if="user.location" class="gl-mb-2 gl-flex">
              <gl-icon name="location" class="gl-shrink-0" />
              <span class="gl-ml-2">{{ user.location }}</span>
            </div>
            <div
              v-if="user.localTime && !user.bot"
              class="gl-mb-2 gl-flex"
              data-testid="user-popover-local-time"
            >
              <gl-icon name="clock" class="gl-shrink-0" />
              <span class="gl-ml-2">{{ user.localTime }}</span>
            </div>
          </div>
          <div v-if="statusHtml" class="gl-mb-2" data-testid="user-popover-status">
            <span v-safe-html:[$options.safeHtmlConfig]="statusHtml"></span>
          </div>
          <div v-if="user.bot && user.websiteUrl" class="gl-text-blue-500">
            <help-icon />
            <gl-link data-testid="user-popover-bot-docs-link" :href="user.websiteUrl">
              <gl-sprintf :message="$options.I18N_USER_LEARN">
                <template #name>{{ user.name }}</template>
              </gl-sprintf>
            </gl-link>
          </div>
        </template>
      </template>
    </div>
  </gl-popover>
</template>
