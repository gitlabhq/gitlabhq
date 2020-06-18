<script>
import ScrollButton from '~/ide/components/jobs/detail/scroll_button.vue';

export default {
  components: {
    ScrollButton,
  },
  props: {
    canScrollUp: {
      type: Boolean,
      required: false,
      default: false,
    },
    canScrollDown: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
};
</script>
<template>
  <div class="controllers">
    <scroll-button :disabled="!canScrollUp" direction="up" @click="$emit('scroll-up')" />
    <scroll-button :disabled="!canScrollDown" direction="down" @click="$emit('scroll-down')" />
  </div>
</template>
