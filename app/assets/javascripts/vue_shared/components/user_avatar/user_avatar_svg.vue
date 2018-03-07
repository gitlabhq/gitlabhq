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

export default {
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
  computed: {
    avatarSizeClass() {
      return `s${this.size}`;
    },
  },
};
</script>

<template>
  <svg
    :class="avatarSizeClass"
    :height="size"
    :width="size"
    v-html="svg"
  />
</template>

