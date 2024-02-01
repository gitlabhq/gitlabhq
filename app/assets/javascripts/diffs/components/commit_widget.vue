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
  <div class="info-well gl-max-w-full mx-0">
    <div class="well-segment">
      <ul class="gl-list-style-none gl-m-0 gl-p-0">
        <commit-item :commit="commit" :collapsible="collapsible" />
      </ul>
    </div>
  </div>
</template>
