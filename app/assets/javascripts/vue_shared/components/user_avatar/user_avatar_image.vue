<script>
/* This is a re-usable vue component for rendering a user avatar that
      does not need to link to the user's profile. The image and an optional
      tooltip can be configured by props passed to this component.

      Sample configuration:

      <user-avatar
        lazy
        :img-src="userAvatarSrc"
        :img-alt="tooltipText"
        :tooltip-text="tooltipText"
        tooltip-placement="top"
        :size="24"
      />

    */

import { GlTooltip, GlAvatar } from '@gitlab/ui';
import { isObject } from 'lodash';
import defaultAvatarUrl from 'images/no_avatar.png';
import { __ } from '~/locale';
import { placeholderImage } from '~/lazy_loader';

export default {
  name: 'UserAvatarImage',
  components: {
    GlTooltip,
    GlAvatar,
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
      type: [Number, Object],
      required: true,
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
    // Render avatar using pseudo-elements so that they cannot be selected or copied
    pseudo: {
      type: Boolean,
      required: false,
      default: false,
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
        baseSrc += `?width=${this.maximumSize}`;
      return baseSrc;
    },
    maximumSize() {
      if (isObject(this.size)) {
        return Math.max(...Object.values(this.size)) * 2;
      }
      return this.size * 2;
    },
    resultantSrcAttribute() {
      return this.lazy ? placeholderImage : this.sanitizedSource;
    },
  },
};
</script>

<template>
  <span ref="userAvatar">
    <gl-avatar
      class="gl-bg-cover"
      :class="{
        lazy: lazy,
        [cssClasses]: true,
      }"
      :src="pseudo ? undefined : resultantSrcAttribute"
      :style="pseudo ? { backgroundImage: `url('${sanitizedSource}')` } : null"
      :data-src="sanitizedSource"
      :size="size"
      :alt="imgAlt"
      data-testid="user-avatar-image"
    />

    <gl-tooltip
      v-if="tooltipText || $scopedSlots.default"
      :target="() => $refs.userAvatar"
      :placement="tooltipPlacement"
      boundary="window"
    >
      <slot>{{ tooltipText }}</slot>
    </gl-tooltip>
  </span>
</template>
