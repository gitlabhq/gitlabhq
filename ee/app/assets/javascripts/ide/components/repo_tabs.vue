<script>
  import { mapGetters } from 'vuex';
  import RepoTab from './repo_tab.vue';

  export default {
    components: {
      'repo-tab': RepoTab,
    },
    computed: {
      ...mapGetters([
        'openFilesMap',
      ]),
    },
  };
</script>

<template>
  <ul
    class="multi-file-tabs list-unstyled append-bottom-0"
  >
    <repo-tab
      v-for="tab in openFilesMap"
      :key="tab.key"
      :tab="tab"
    />
  </ul>
</template>
