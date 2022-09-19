<script>
import RunnerTag from './runner_tag.vue';

export default {
  components: {
    RunnerTag,
  },
  props: {
    tagList: {
      type: Array,
      required: false,
      default: () => [],
    },
    size: {
      type: String,
      required: false,
      default: 'sm',
    },
  },
};
</script>
<template>
  <span v-if="tagList && tagList.length">
    <runner-tag
      v-for="tag in tagList"
      :key="tag"
      class="gl-display-inline gl-mr-1"
      :tag="tag"
      :size="size"
    />
  </span>
</template>
