<script>
import RepoStore from '../stores/repo_store';

export default {
  data: () => RepoStore,
}
</script>

<template>
<div v-html="activeFile.html"></div>
</template>
