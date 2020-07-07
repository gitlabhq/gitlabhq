<script>
import { GlPopover, GlSkeletonLoading } from '@gitlab/ui';
import Icon from '~/vue_shared/components/icon.vue';
import UserAvatarImage from '../user_avatar/user_avatar_image.vue';
import { glEmojiTag } from '../../../emoji';

const MAX_SKELETON_LINES = 4;

export default {
  name: 'UserPopover',
  maxSkeletonLines: MAX_SKELETON_LINES,
  components: {
    Icon,
    GlPopover,
    GlSkeletonLoading,
    UserAvatarImage,
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
  },
};
</script>

<template>
  <!-- 200ms delay so not every mouseover triggers Popover -->
  <gl-popover :target="target" :delay="200" boundary="viewport" triggers="hover" placement="top">
    <div class="user-popover d-flex">
      <div class="p-1 flex-shrink-1">
        <user-avatar-image :img-src="user.avatarUrl" :size="60" css-classes="mr-2" />
      </div>
      <div class="p-1 w-100">
        <template v-if="userIsLoading">
          <!-- `gl-skeleton-loading` does not support equal length lines -->
          <!-- This can be migrated to `gl-skeleton-loader` when https://gitlab.com/gitlab-org/gitlab-ui/-/issues/872 is completed -->
          <gl-skeleton-loading
            v-for="n in $options.maxSkeletonLines"
            :key="n"
            :lines="1"
            class="animation-container-small mb-1"
          />
        </template>
        <template v-else>
          <div class="mb-2">
            <h5 class="m-0">
              {{ user.name }}
            </h5>
            <span class="text-secondary">@{{ user.username }}</span>
          </div>
          <div class="text-secondary">
            <div v-if="user.bio" class="d-flex mb-1">
              <icon name="profile" class="category-icon flex-shrink-0" />
              <span ref="bio" class="ml-1">{{ user.bio }}</span>
            </div>
            <div v-if="user.workInformation" class="d-flex mb-1">
              <icon name="work" class="category-icon flex-shrink-0" />
              <span ref="workInformation" class="ml-1">{{ user.workInformation }}</span>
            </div>
          </div>
          <div class="js-location text-secondary d-flex">
            <div v-if="user.location">
              <icon name="location" class="category-icon flex-shrink-0" />
              <span class="ml-1">{{ user.location }}</span>
            </div>
          </div>
          <div v-if="statusHtml" class="js-user-status mt-2">
            <span v-html="statusHtml"></span>
          </div>
        </template>
      </div>
    </div>
  </gl-popover>
</template>
