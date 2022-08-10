<script>
/* This is a re-usable vue component for rendering a user avatar that
      does not need to link to the user's profile. The image and an optional
      tooltip can be configured by props passed to this component.

      Sample configuration:

      <user-avatar-image
        lazy
        :img-src="userAvatarSrc"
        :img-alt="tooltipText"
        :tooltip-text="tooltipText"
        tooltip-placement="top"
      />

    */

import defaultAvatarUrl from 'images/no_avatar.png';
import { __ } from '~/locale';
import glFeatureFlagMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import UserAvatarImageNew from './user_avatar_image_new.vue';
import UserAvatarImageOld from './user_avatar_image_old.vue';

export default {
  name: 'UserAvatarImage',
  components: {
    UserAvatarImageNew,
    UserAvatarImageOld,
  },
  mixins: [glFeatureFlagMixin()],
  props: {
    lazy: {
      type: Boolean,
      required: false,
      default: false,
    },
    imgSrc: {
      type: String,
      required: false,
      default: defaultAvatarUrl,
    },
    cssClasses: {
      type: String,
      required: false,
      default: '',
    },
    imgAlt: {
      type: String,
      required: false,
      default: __('user avatar'),
    },
    size: {
      type: [Number, Object],
      required: false,
      default: 20,
    },
    tooltipText: {
      type: String,
      required: false,
      default: '',
    },
    tooltipPlacement: {
      type: String,
      required: false,
      default: 'top',
    },
    enforceGlAvatar: {
      type: Boolean,
      required: false,
    },
  },
};
</script>

<template>
  <user-avatar-image-new
    v-if="glFeatures.glAvatarForAllUserAvatars || enforceGlAvatar"
    v-bind="$props"
  >
    <slot></slot>
  </user-avatar-image-new>
  <user-avatar-image-old v-else v-bind="$props">
    <slot></slot>
  </user-avatar-image-old>
</template>
