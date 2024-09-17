<script>
import CommitItem from './commit_item.vue';

export default {
  components: {
    CommitItem,
  },
  props: {
    commit: {
      type: Object,
      required: true,
    },
    collapsible: {
      type: Boolean,
      required: false,
      default: true,
    },
  },
};
</script>

<template>
  <div class="info-well mx-0 gl-max-w-full">
    <div class="well-segment">
      <ul class="gl-m-0 gl-list-none gl-p-0">
        <commit-item :commit="commit" :collapsible="collapsible" />
      </ul>
    </div>
  </div>
</template>
