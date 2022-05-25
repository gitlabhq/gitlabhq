<script>
import {
  GlPopover,
  GlLink,
  GlSkeletonLoader,
  GlIcon,
  GlSafeHtmlDirective,
  GlSprintf,
  GlButton,
} from '@gitlab/ui';
import { __ } from '~/locale';
import UserNameWithStatus from '~/sidebar/components/assignees/user_name_with_status.vue';
import { glEmojiTag } from '~/emoji';
import createFlash from '~/flash';
import { followUser, unfollowUser } from '~/rest_api';
import UserAvatarImage from '../user_avatar/user_avatar_image.vue';
import { USER_POPOVER_DELAY } from './constants';

const MAX_SKELETON_LINES = 4;

export default {
  name: 'UserPopover',
  maxSkeletonLines: MAX_SKELETON_LINES,
  USER_POPOVER_DELAY,
  components: {
    GlIcon,
    GlLink,
    GlPopover,
    GlSkeletonLoader,
    UserAvatarImage,
    UserNameWithStatus,
    GlSprintf,
    GlButton,
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
  <!-- delay so not every mouseover triggers Popover -->
  <gl-popover
    :show="show"
    :target="target"
    :delay="$options.USER_POPOVER_DELAY"
    :placement="placement"
    boundary="viewport"
    triggers="hover focus manual"
  >
    <div class="gl-p-3 gl-line-height-normal gl-display-flex" data-testid="user-popover">
      <div
        class="gl-p-2 flex-shrink-1 gl-display-flex gl-flex-direction-column align-items-center gl-w-70p"
      >
        <user-avatar-image :img-src="user.avatarUrl" :size="64" css-classes="gl-m-0!" />
        <div v-if="shouldRenderToggleFollowButton" class="gl-mt-3">
          <gl-button
            :variant="toggleFollowButtonVariant"
            :loading="toggleFollowLoading"
            size="small"
            data-testid="toggle-follow-button"
            @click="toggleFollow"
            >{{ toggleFollowButtonText }}</gl-button
          >
        </div>
      </div>
      <div class="gl-w-full gl-min-w-0 gl-word-break-word">
        <template v-if="userIsLoading">
          <gl-skeleton-loader
            :lines="$options.maxSkeletonLines"
            preserve-aspect-ratio="none"
            equal-width-lines
            :height="52"
          />
        </template>
        <template v-else>
          <div class="gl-mb-3">
            <h5 class="gl-m-0">
              <user-name-with-status
                :name="user.name"
                :availability="availabilityStatus"
                :pronouns="user.pronouns"
              />
            </h5>
            <span class="gl-text-gray-500">@{{ user.username }}</span>
          </div>
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
    </div>
  </gl-popover>
</template>
