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

import defaultAvatarUrl from 'images/no_avatar.png';
import { placeholderImage } from '../../../lazy_loader';
import tooltip from '../../directives/tooltip';

export default {
  name: 'UserAvatarImage',
  directives: {
    tooltip,
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
    // API response sends null when gravatar is disabled and
    // we provide an empty string when we use it inside user avatar link.
    // In both cases we should render the defaultAvatarUrl
    sanitizedSource() {
      let baseSrc = this.imgSrc === '' || this.imgSrc === null ? defaultAvatarUrl : this.imgSrc;
      if (baseSrc.indexOf('?') === -1) baseSrc += `?width=${this.size}`;
      return baseSrc;
    },
    resultantSrcAttribute() {
      return this.lazy ? placeholderImage : this.sanitizedSource;
    },
    tooltipContainer() {
      return this.tooltipText ? 'body' : null;
    },
    avatarSizeClass() {
      return `s${this.size}`;
    },
    showImage() {
      return this.imgSrc !== 'no-avatar';
    },
  },
};
</script>

<template>
  <img
    v-tooltip
    v-if="showImage"
    :class="{
      lazy: lazy,
      [avatarSizeClass]: true,
      [cssClasses]: true
    }"
    :src="resultantSrcAttribute"
    :width="size"
    :height="size"
    :alt="imgAlt"
    :data-src="sanitizedSource"
    :data-container="tooltipContainer"
    :data-placement="tooltipPlacement"
    :title="tooltipText"
    class="avatar"
    data-boundary="window"
  />
</template>
