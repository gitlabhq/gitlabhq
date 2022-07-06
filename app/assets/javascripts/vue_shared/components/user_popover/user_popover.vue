<script>
import {
  GlPopover,
  GlLink,
  GlSkeletonLoader,
  GlIcon,
  GlSafeHtmlDirective,
  GlSprintf,
  GlButton,
  GlAvatarLabeled,
} from '@gitlab/ui';
import { __ } from '~/locale';
import { glEmojiTag } from '~/emoji';
import createFlash from '~/flash';
import { followUser, unfollowUser } from '~/rest_api';
import { isUserBusy } from '~/set_status_modal/utils';
import { USER_POPOVER_DELAY } from './constants';

const MAX_SKELETON_LINES = 4;

export default {
  name: 'UserPopover',
  maxSkeletonLines: MAX_SKELETON_LINES,
  USER_POPOVER_DELAY,
  i18n: {
    busy: __('Busy'),
  },
  components: {
    GlIcon,
    GlLink,
    GlPopover,
    GlSkeletonLoader,
    GlSprintf,
    GlButton,
    GlAvatarLabeled,
  },
  directives: {
    SafeHtml: GlSafeHtmlDirective,
  },
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
      } else if (this.user.status.message_html) {
        return this.user.status.message_html;
      }

      return '';
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

      return this.user?.isFollowed ? __('Unfollow') : __('Follow');
    },
    toggleFollowButtonVariant() {
      return this.user?.isFollowed ? 'default' : 'confirm';
    },
    hasPronouns() {
      return Boolean(this.user?.pronouns?.trim());
    },
    isBusy() {
      return isUserBusy(this.availabilityStatus);
    },
    username() {
      return `@${this.user?.username}`;
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
      try {
        await followUser(this.user.id);
        this.$emit('follow');
      } catch (error) {
        createFlash({
          message: __('An error occurred while trying to follow this user, please try again.'),
          error,
          captureError: true,
        });
      } finally {
        this.toggleFollowLoading = false;
      }
    },
    async unfollow() {
      this.toggleFollowLoading = true;
      try {
        await unfollowUser(this.user.id);
        this.$emit('unfollow');
      } catch (error) {
        createFlash({
          message: __('An error occurred while trying to unfollow this user, please try again.'),
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
    :css-classes="['gl-max-w-48']"
    :show="show"
    :target="target"
    :delay="$options.USER_POPOVER_DELAY"
    :placement="placement"
    boundary="viewport"
    triggers="hover focus manual"
    data-testid="user-popover"
  >
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
      >
        <gl-button
          v-if="shouldRenderToggleFollowButton"
          class="gl-mt-3 gl-align-self-start"
          :variant="toggleFollowButtonVariant"
          :loading="toggleFollowLoading"
          size="small"
          data-testid="toggle-follow-button"
          @click="toggleFollow"
          >{{ toggleFollowButtonText }}</gl-button
        >

        <template #meta>
          <span
            v-if="hasPronouns"
            class="gl-text-gray-500 gl-font-sm gl-font-weight-normal gl-p-1"
            data-testid="user-popover-pronouns"
            >({{ user.pronouns }})</span
          >
          <span v-if="isBusy" class="gl-text-gray-500 gl-font-sm gl-font-weight-normal gl-p-1"
            >({{ $options.i18n.busy }})</span
          >
        </template>
      </gl-avatar-labeled>
    </div>
    <div class="gl-mt-2 gl-w-full gl-word-break-word">
      <template v-if="userIsLoading">
        <gl-skeleton-loader
          :lines="$options.maxSkeletonLines"
          preserve-aspect-ratio="none"
          equal-width-lines
          :height="24"
        />
      </template>
      <template v-else>
        <div class="gl-text-gray-500">
          <div v-if="user.bio" class="gl-display-flex gl-mb-2">
            <gl-icon name="profile" class="gl-flex-shrink-0" />
            <span ref="bio" class="gl-ml-2">{{ user.bio }}</span>
          </div>
          <div v-if="user.workInformation" class="gl-display-flex gl-mb-2">
            <gl-icon name="work" class="gl-flex-shrink-0" />
            <span ref="workInformation" class="gl-ml-2">{{ user.workInformation }}</span>
          </div>
          <div v-if="user.location" class="gl-display-flex gl-mb-2">
            <gl-icon name="location" class="gl-flex-shrink-0" />
            <span class="gl-ml-2">{{ user.location }}</span>
          </div>
          <div
            v-if="user.localTime && !user.bot"
            class="gl-display-flex gl-mb-2"
            data-testid="user-popover-local-time"
          >
            <gl-icon name="clock" class="gl-flex-shrink-0" />
            <span class="gl-ml-2">{{ user.localTime }}</span>
          </div>
        </div>
        <div v-if="statusHtml" class="gl-mb-2" data-testid="user-popover-status">
          <span v-safe-html:[$options.safeHtmlConfig]="statusHtml"></span>
        </div>
        <div v-if="user.bot && user.websiteUrl" class="gl-text-blue-500">
          <gl-icon name="question" />
          <gl-link data-testid="user-popover-bot-docs-link" :href="user.websiteUrl">
            <gl-sprintf :message="__('Learn more about %{username}')">
              <template #username>{{ user.name }}</template>
            </gl-sprintf>
          </gl-link>
        </div>
      </template>
    </div>
  </gl-popover>
</template>
