<script>

/* This is a re-usable vue component for rendering a user avatar that
  does not need to link to the user's profile. The image and an optional
  tooltip can be configured by props passed to this component.

  Sample configuration:

  <user-avatar-image
    :img-src="userAvatarSrc"
    :img-alt="tooltipText"
    :tooltip-text="tooltipText"
    tooltip-placement="top"
  />

*/

import defaultAvatarUrl from 'images/no_avatar.png';
import TooltipMixin from '../../mixins/tooltip';

export default {
  name: 'UserAvatarImage',
  mixins: [TooltipMixin],
  props: {
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
      default: 'user avatar',
    },
    size: {
      type: Number,
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
  },
  computed: {
    tooltipContainer() {
      return this.tooltipText ? 'body' : null;
    },
    avatarSizeClass() {
      return `s${this.size}`;
    },
  },
};
</script>

<template>
  <img
    class="avatar"
    :class="[avatarSizeClass, cssClasses]"
    :src="imgSrc"
    :width="size"
    :height="size"
    :alt="imgAlt"
    :data-container="tooltipContainer"
    :data-placement="tooltipPlacement"
    :title="tooltipText"
    ref="tooltip"
  />
</template>
