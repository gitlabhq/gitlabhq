<script>
import CommitFilteredSearch from './commit_filtered_search.vue';

export default {
  name: 'CommitHeader',
  components: {
    CommitFilteredSearch,
  },
};
</script>

<template>
  <div>
    <h1 class="gl-text-size-h1">{{ __('Commits') }}</h1>
    <commit-filtered-search class="gl-mt-5" @filter="$emit('filter', $event)" />
  </div>
</template>
