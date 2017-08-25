<script>
export default {
  name: 'repo-file-info',
  props: {
    branchName: {
      type: String,
      required: true,
    },
    lastCommitHash: {
      type: String,
      required: true,
      default: '',
    },
    lastCommitUrl: {
      type: String,
      required: true,
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
    <i
      aria-label="branch"
      class="fa fa-code-fork"
    />
    <span>{{branchName}}</span>
    <span class="prepend-left-10">Latest commit:</span>
    <a
      v-if="lastCommitHash.length > 0"
      :href="lastCommitUrl"
    >
      {{lastCommitHash.slice(0, 8)}}
    </a>
    <i
      v-else
      aria-label="loading"
      class="fa fa-spinner fa-spin"
    />
    <span class="pull-right">{{mimeType}}</span>
  </div>
</template>
