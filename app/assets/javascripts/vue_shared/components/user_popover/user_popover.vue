<script>
import { GlPopover, GlSkeletonLoading, GlSprintf } from '@gitlab/ui';
import Icon from '~/vue_shared/components/icon.vue';
import UserAvatarImage from '../user_avatar/user_avatar_image.vue';
import { glEmojiTag } from '../../../emoji';
import { s__ } from '~/locale';
import { isString } from 'lodash';

export default {
  name: 'UserPopover',
  components: {
    Icon,
    GlPopover,
    GlSkeletonLoading,
    GlSprintf,
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
    nameIsLoading() {
      return !this.user.name;
    },
    workInformationIsLoading() {
      return !this.user.loaded && this.workInformation === null;
    },
    workInformation() {
      const { jobTitle, organization } = this.user;

      if (organization && jobTitle) {
        return {
          message: s__('Profile|%{job_title} at %{organization}'),
          placeholders: { job_title: jobTitle, organization },
        };
      } else if (organization) {
        return organization;
      } else if (jobTitle) {
        return jobTitle;
      }

      return null;
    },
    workInformationShouldUseSprintf() {
      return !isString(this.workInformation);
    },
    locationIsLoading() {
      return !this.user.loaded && this.user.location === null;
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
        <h5 class="m-0">
          <span v-if="user.name">{{ user.name }}</span>
          <gl-skeleton-loading v-else :lines="1" class="animation-container-small mb-1" />
        </h5>
        <div class="text-secondary mb-2">
          <span v-if="user.username">@{{ user.username }}</span>
          <gl-skeleton-loading v-else :lines="1" class="animation-container-small mb-1" />
        </div>
        <div class="text-secondary">
          <div v-if="user.bio" class="d-flex mb-1">
            <icon name="profile" class="category-icon flex-shrink-0" />
            <span ref="bio" class="ml-1">{{ user.bio }}</span>
          </div>
          <div v-if="workInformation" class="d-flex mb-1">
            <icon
              v-show="!workInformationIsLoading"
              name="work"
              class="category-icon flex-shrink-0"
            />
            <span ref="workInformation" class="ml-1">
              <gl-sprintf v-if="workInformationShouldUseSprintf" :message="workInformation.message">
                <template
                  v-for="(placeholder, slotName) in workInformation.placeholders"
                  v-slot:[slotName]
                >
                  <span :key="slotName">{{ placeholder }}</span>
                </template>
              </gl-sprintf>
              <span v-else>{{ workInformation }}</span>
            </span>
          </div>
          <gl-skeleton-loading
            v-if="workInformationIsLoading"
            :lines="1"
            class="animation-container-small mb-1"
          />
        </div>
        <div class="js-location text-secondary d-flex">
          <icon
            v-show="!locationIsLoading && user.location"
            name="location"
            class="category-icon flex-shrink-0"
          />
          <span v-if="user.location" class="ml-1">{{ user.location }}</span>
          <gl-skeleton-loading
            v-if="locationIsLoading"
            :lines="1"
            class="animation-container-small mb-1"
          />
        </div>
        <div v-if="statusHtml" class="js-user-status mt-2">
          <span v-html="statusHtml"></span>
        </div>
      </div>
    </div>
  </gl-popover>
</template>
