<script>
export default {
  name: 'repo-file-info',
  props: {
    branchName: {
      type: String,
      required: true,
    },
    latestCommitHash: {
      type: String,
      required: false,
      default: '2b827d05',
    },
    mimeType: {
      type: String,
      required: true,
    },
  },
};
</script>

<template>
  <div class="repo-file-info">
    <i aria-label="branch" class="fa fa-code-fork" />
    <span>{{branchName}}</span>

    <span class="prepend-left-10">Latest Commit:</span>
    <a href="#">{{latestCommitHash}}</a>

    <span class="pull-right">{{mimeType}}</span>
  </div>
</template>
