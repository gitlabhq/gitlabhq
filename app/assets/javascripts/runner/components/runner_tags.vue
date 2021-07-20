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
      default: 'md',
    },
  },
};
</script>
<template>
  <div>
    <runner-tag v-for="tag in tagList" :key="tag" :tag="tag" :size="size" />
  </div>
</template>
