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
  <div class="info-well mw-100 mx-0">
    <div class="well-segment">
      <ul class="blob-commit-info">
        <commit-item :commit="commit" :collapsible="collapsible" />
      </ul>
    </div>
  </div>
</template>
