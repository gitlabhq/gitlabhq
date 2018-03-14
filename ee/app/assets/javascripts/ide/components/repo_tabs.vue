<script>
  import RepoTab from './repo_tab.vue';

  export default {
    components: {
      RepoTab,
    },
    props: {
      files: {
        type: Array,
        required: true,
      },
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
