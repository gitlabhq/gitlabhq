<script>

/* This is a re-usable vue component for rendering a user avatar svg (typically
  for a blank state). It will receive styles comparable to the user avatar,
  but no image is loaded, it isn't wrapped in a link, and tooltips aren't supported.
  The svg and avatar size can be configured by props passed to this component.

  Sample configuration:

  <user-avatar-svg
    :svg="potentialApproverSvg"
    :size="20"
  />

*/

import UserAvatarSizeMixin from './user_avatar_size_mixin';

export default {
  mixins: [UserAvatarSizeMixin],
  props: {
    svg: {
      type: String,
      required: true,
    },
    size: {
      type: Number,
      required: false,
      default: 20,
    },
  },
};
</script>

<template>
  <svg
    :class="avatarSizeClass"
    :style="avatarSizeStylesMap"
    v-html="svg">
  </svg>
</template>

