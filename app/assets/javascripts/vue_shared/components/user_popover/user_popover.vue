<script>
/* eslint-disable vue/no-v-html */
import {
  GlPopover,
  GlLink,
  GlDeprecatedSkeletonLoading as GlSkeletonLoading,
  GlIcon,
} from '@gitlab/ui';
import UserAvailabilityStatus from '~/set_status_modal/components/user_availability_status.vue';
import UserAvatarImage from '../user_avatar/user_avatar_image.vue';
import { glEmojiTag } from '../../../emoji';

const MAX_SKELETON_LINES = 4;

const SECURITY_BOT_USER_DATA = {
  username: 'GitLab-Security-Bot',
  name: 'GitLab Security Bot',
};

export default {
  name: 'UserPopover',
  maxSkeletonLines: MAX_SKELETON_LINES,
  components: {
    GlIcon,
    GlLink,
    GlPopover,
    GlSkeletonLoading,
    UserAvatarImage,
    UserAvailabilityStatus,
  },
  props: {
    target: {
      type: HTMLAnchorElement,
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
    isSecurityBot() {
      const { username, name, websiteUrl = '' } = this.user;
      return (
        gon.features?.securityAutoFix &&
        username === SECURITY_BOT_USER_DATA.username &&
        name === SECURITY_BOT_USER_DATA.name &&
        websiteUrl.length
      );
    },
    availabilityStatus() {
      return this.user?.status?.availability || null;
    },
  },
};
</script>

<template>
  <!-- 200ms delay so not every mouseover triggers Popover -->
  <gl-popover :target="target" :delay="200" boundary="viewport" triggers="hover" placement="top">
    <div class="gl-p-3 gl-line-height-normal gl-display-flex" data-testid="user-popover">
      <div class="gl-p-2 flex-shrink-1">
        <user-avatar-image :img-src="user.avatarUrl" :size="60" css-classes="gl-mr-3!" />
      </div>
      <div class="gl-p-2 gl-w-full">
        <template v-if="userIsLoading">
          <!-- `gl-skeleton-loading` does not support equal length lines -->
          <!-- This can be migrated to `gl-skeleton-loader` when https://gitlab.com/gitlab-org/gitlab-ui/-/issues/872 is completed -->
          <gl-skeleton-loading
            v-for="n in $options.maxSkeletonLines"
            :key="n"
            :lines="1"
            class="animation-container-small gl-mb-2"
          />
        </template>
        <template v-else>
          <div class="gl-mb-3">
            <h5 class="gl-m-0">
              {{ user.name }}
              <user-availability-status
                v-if="availabilityStatus"
                :availability="availabilityStatus"
              />
            </h5>
            <span class="gl-text-gray-500">@{{ user.username }}</span>
          </div>
          <div class="gl-text-gray-500">
            <div v-if="user.bio" class="gl-display-flex gl-mb-2">
              <gl-icon name="profile" class="gl-text-gray-400 gl-flex-shrink-0" />
              <span ref="bio" class="gl-ml-2" v-html="user.bioHtml"></span>
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
          <div v-if="isSecurityBot" class="gl-text-blue-500">
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
