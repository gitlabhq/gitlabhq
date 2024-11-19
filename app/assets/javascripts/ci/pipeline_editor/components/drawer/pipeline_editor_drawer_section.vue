<script>
export default {
  props: {
    emoji: {
      type: String,
      required: true,
    },
    title: {
      type: String,
      required: true,
    },
  },
};
</script>
<template>
  <div class="gl-pb-6 gl-leading-20">
    <span class="gl-flex gl-items-baseline">
      <gl-emoji class="gl-mr-3" :data-name="emoji" data-testid="title-emoji" />
      <h4 class="gl-text-lg">{{ title }}</h4>
    </span>
    <slot></slot>
  </div>
</template>
