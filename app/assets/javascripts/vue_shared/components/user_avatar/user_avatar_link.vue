<script>
/* This is a re-usable vue component for rendering a user avatar wrapped in
  a clickable link (likely to the user's profile). The link, image, and
  tooltip can be configured by props passed to this component.

  Sample configuration:

  <user-avatar-link
    :link-href="userProfileUrl"
    :img-src="userAvatarSrc"
    :img-alt="tooltipText"
    :img-size="20"
    :tooltip-text="tooltipText"
    :tooltip-placement="top"
    :username="username"
  />

*/

import glFeatureFlagMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import UserAvatarLinkNew from './user_avatar_link_new.vue';
import UserAvatarLinkOld from './user_avatar_link_old.vue';

export default {
  name: 'UserAvatarLink',
  components: {
    UserAvatarLinkNew,
    UserAvatarLinkOld,
  },
  mixins: [glFeatureFlagMixin()],
  props: {
    lazy: {
      type: Boolean,
      required: false,
      default: false,
    },
    linkHref: {
      type: String,
      required: false,
      default: '',
    },
    imgSrc: {
      type: String,
      required: false,
      default: '',
    },
    imgAlt: {
      type: String,
      required: false,
      default: '',
    },
    imgCssClasses: {
      type: String,
      required: false,
      default: '',
    },
    imgSize: {
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
    username: {
      type: String,
      required: false,
      default: '',
    },
    enforceGlAvatar: {
      type: Boolean,
      required: false,
    },
  },
};
</script>

<template>
  <user-avatar-link-new
    v-if="glFeatures.glAvatarForAllUserAvatars || enforceGlAvatar"
    v-bind="$props"
  >
    <slot></slot>
    <template #avatar-badge>
      <slot name="avatar-badge"></slot>
    </template>
  </user-avatar-link-new>

  <user-avatar-link-old v-else v-bind="$props">
    <slot></slot>
    <template #avatar-badge>
      <slot name="avatar-badge"></slot>
    </template>
  </user-avatar-link-old>
</template>
