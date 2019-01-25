<script>
import { GlPopover, GlSkeletonLoading } from '@gitlab/ui';
import { __, sprintf } from '~/locale';
import UserAvatarImage from '../user_avatar/user_avatar_image.vue';
import { glEmojiTag } from '../../../emoji';

export default {
  name: 'UserPopover',
  components: {
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
    loaded: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  computed: {
    jobLine() {
      if (this.user.bio && this.user.organization) {
        return sprintf(
          __('%{bio} at %{organization}'),
          {
            bio: this.user.bio,
            organization: this.user.organization,
          },
          false,
        );
      } else if (this.user.bio) {
        return this.user.bio;
      } else if (this.user.organization) {
        return this.user.organization;
      }
      return null;
    },
    statusHtml() {
      if (this.user.status.emoji && this.user.status.message_html) {
        return `${glEmojiTag(this.user.status.emoji)} ${this.user.status.message_html}`;
      } else if (this.user.status.message_html) {
        return this.user.status.message_html;
      }
      return '';
    },
    nameIsLoading() {
      return !this.user.name;
    },
    jobInfoIsLoading() {
      return !this.user.loaded && this.user.organization === null;
    },
    locationIsLoading() {
      return !this.user.loaded && this.user.location === null;
    },
  },
};
</script>

<template>
  <gl-popover :target="target" boundary="viewport" placement="top" show>
    <div class="user-popover d-flex">
      <div class="p-1 flex-shrink-1">
        <user-avatar-image :img-src="user.avatarUrl" :size="60" css-classes="mr-2" />
      </div>
      <div class="p-1 w-100">
        <h5 class="m-0">
          {{ user.name }}
          <gl-skeleton-loading
            v-if="nameIsLoading"
            :lines="1"
            class="animation-container-small mb-1"
          />
        </h5>
        <div class="text-secondary mb-2">
          <span v-if="user.username">@{{ user.username }}</span>
          <gl-skeleton-loading v-else :lines="1" class="animation-container-small mb-1" />
        </div>
        <div class="text-secondary">
          {{ jobLine }}
          <gl-skeleton-loading
            v-if="jobInfoIsLoading"
            :lines="1"
            class="animation-container-small mb-1"
          />
        </div>
        <div class="text-secondary">
          {{ user.location }}
          <gl-skeleton-loading
            v-if="locationIsLoading"
            :lines="1"
            class="animation-container-small mb-1"
          />
        </div>
        <div v-if="user.status" class="mt-2"><span v-html="statusHtml"></span></div>
      </div>
    </div>
  </gl-popover>
</template>
