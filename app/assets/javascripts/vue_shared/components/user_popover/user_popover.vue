<script>
/* eslint-disable vue/no-v-html */
import { GlPopover, GlLink, GlSkeletonLoader, GlIcon } from '@gitlab/ui';
import UserNameWithStatus from '~/sidebar/components/assignees/user_name_with_status.vue';
import { glEmojiTag } from '../../../emoji';
import UserAvatarImage from '../user_avatar/user_avatar_image.vue';

const MAX_SKELETON_LINES = 4;

export default {
  name: 'UserPopover',
  maxSkeletonLines: MAX_SKELETON_LINES,
  components: {
    GlIcon,
    GlLink,
    GlPopover,
    GlSkeletonLoader,
    UserAvatarImage,
    UserNameWithStatus,
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
  },
};
</script>

<template>
  <!-- 200ms delay so not every mouseover triggers Popover -->
  <gl-popover :target="target" :delay="200" boundary="viewport" placement="top">
    <div class="gl-p-3 gl-line-height-normal gl-display-flex" data-testid="user-popover">
      <div class="gl-p-2 flex-shrink-1">
        <user-avatar-image :img-src="user.avatarUrl" :size="60" css-classes="gl-mr-3!" />
      </div>
      <div class="gl-p-2 gl-w-full gl-min-w-0">
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
              <gl-icon name="profile" class="gl-text-gray-400 gl-flex-shrink-0" />
              <span ref="bio" class="gl-ml-2 gl-overflow-hidden" v-html="user.bioHtml"></span>
            </div>
            <div v-if="user.workInformation" class="gl-display-flex gl-mb-2">
              <gl-icon name="work" class="gl-text-gray-400 gl-flex-shrink-0" />
              <span ref="workInformation" class="gl-ml-2">{{ user.workInformation }}</span>
            </div>
          </div>
          <div v-if="user.location" class="js-location gl-text-gray-500 gl-display-flex">
            <gl-icon name="location" class="gl-text-gray-400 flex-shrink-0" />
            <span class="gl-ml-2">{{ user.location }}</span>
          </div>
          <div v-if="statusHtml" class="js-user-status gl-mt-3">
            <span v-html="statusHtml"></span>
          </div>
          <div v-if="user.bot" class="gl-text-blue-500">
            <gl-icon name="question" />
            <gl-link data-testid="user-popover-bot-docs-link" :href="user.websiteUrl">
              {{ sprintf(__('Learn more about %{username}'), { username: user.name }) }}
            </gl-link>
          </div>
        </template>
      </div>
    </div>
  </gl-popover>
</template>
