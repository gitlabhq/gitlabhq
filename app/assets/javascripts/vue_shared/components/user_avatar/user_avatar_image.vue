<script>
/* This is a re-usable vue component for rendering a user avatar that
  does not need to link to the user's profile. The image and an optional
  tooltip can be configured by props passed to this component.

  Sample configuration:

  <user-avatar-image
    :lazy="true"
    :img-src="userAvatarSrc"
    :img-alt="tooltipText"
    :tooltip-text="tooltipText"
    tooltip-placement="top"
  />

*/

import { GlTooltip } from '@gitlab/ui';
import defaultAvatarUrl from 'images/no_avatar.png';
import { __ } from '~/locale';
import { placeholderImage } from '../../../lazy_loader';

export default {
  name: 'UserAvatarImage',
  components: {
    GlTooltip,
  },
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
    // API response sends null when gravatar is disabled and
    // we provide an empty string when we use it inside user avatar link.
    // In both cases we should render the defaultAvatarUrl
    sanitizedSource() {
      let baseSrc = this.imgSrc === '' || this.imgSrc === null ? defaultAvatarUrl : this.imgSrc;
      // Only adds the width to the URL if its not a base64 data image
      if (!(baseSrc.indexOf('data:') === 0) && !baseSrc.includes('?'))
        baseSrc += `?width=${this.size}`;
      return baseSrc;
    },
    resultantSrcAttribute() {
      return this.lazy ? placeholderImage : this.sanitizedSource;
    },
    avatarSizeClass() {
      return `s${this.size}`;
    },
  },
};
</script>

<template>
  <span>
    <img
      ref="userAvatarImage"
      :class="{
        lazy: lazy,
        [avatarSizeClass]: true,
        [cssClasses]: true,
      }"
      :src="resultantSrcAttribute"
      :width="size"
      :height="size"
      :alt="imgAlt"
      :data-src="sanitizedSource"
      class="avatar"
    />
    <gl-tooltip
      v-if="tooltipText || $slots.default"
      :target="() => $refs.userAvatarImage"
      :placement="tooltipPlacement"
      boundary="window"
      class="js-user-avatar-image-tooltip"
    >
      <slot> {{ tooltipText }} </slot>
    </gl-tooltip>
  </span>
</template>
