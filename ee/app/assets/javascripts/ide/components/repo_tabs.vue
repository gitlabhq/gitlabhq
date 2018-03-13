<script>
  import { mapGetters } from 'vuex';
  import RepoTab from './repo_tab.vue';

  export default {
    components: {
      'repo-tab': RepoTab,
    },
    props: {
      files: {
        type: Array,
        required: true,
      },
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
      v-for="file in files"
      :key="file.key"
      :tab="file"
    />
  </ul>
</template>
