<script>
import CommitListHeader from './commit_list_header.vue';
import CommitListItem from './commit_list_item.vue';

export default {
  name: 'CommitListApp',
  components: {
    CommitListHeader,
    CommitListItem,
  },
  data() {
    return {
      commits: [],
    };
  },
  computed: {},
};
</script>

<template>
  <div class="gl-mt-5">
    <commit-list-header />
    <commit-list-item v-for="commit in commits" :key="commit.id" :commit="commit" />
  </div>
</template>
