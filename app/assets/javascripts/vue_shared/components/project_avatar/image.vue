<script>
/* This is a re-usable vue component for rendering a project avatar that
    does not need to link to the project's profile. The image and an optional
    tooltip can be configured by props passed to this component.

    Sample configuration:

    <project-avatar-image
      :lazy="true"
      :img-src="projectAvatarSrc"
      :img-alt="tooltipText"
      :tooltip-text="tooltipText"
      tooltip-placement="top"
    />

  */
import defaultAvatarUrl from 'images/no_avatar.png';
import { __ } from '~/locale';
import { placeholderImage } from '../../../lazy_loader';

export default {
  name: 'ProjectAvatarImage',
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
      default: __('project avatar'),
    },
    size: {
      type: Number,
      required: false,
      default: 20,
    },
  },
  computed: {
    // API response sends null when gravatar is disabled and
    // we provide an empty string when we use it inside project avatar link.
    // In both cases we should render the defaultAvatarUrl
    sanitizedSource() {
      return this.imgSrc === '' || this.imgSrc === null ? defaultAvatarUrl : this.imgSrc;
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
  <img
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
</template>
