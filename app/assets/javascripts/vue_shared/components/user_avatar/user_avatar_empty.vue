<script>
import tooltip from '../../directives/tooltip';

export default {
  name: 'UserAvatarEmpty',
  directives: {
    tooltip,
  },
  props: {
    cssClasses: {
      type: String,
      required: false,
      default: '',
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
  <span
    v-tooltip
    :class="{
      [avatarSizeClass]: true,
      [cssClasses]: true
    }"
    :width="size"
    :height="size"
    :data-container="tooltipContainer"
    :data-placement="tooltipPlacement"
    :title="tooltipText"
    class="avatar no-avatar"
    data-boundary="window"
  >
  </span>
</template>
