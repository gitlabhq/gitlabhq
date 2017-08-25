<script>
export default {
  name: 'repo-file-footer',
  props: {
    branchName: {
      type: String,
      required: true,
    },
    lastCommitHash: {
      type: String,
      required: true,
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
  computed: {
    abbreviatedLastCommitHash() {
      return this.lastCommitHash.slice(0, 8);
    },
  },
};
</script>

<template>
  <div class="repo-file-footer">
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
      {{abbreviatedLastCommitHash}}
    </a>
    <i
      v-else
      aria-label="loading"
      class="fa fa-spinner fa-spin"
    />
    <span class="pull-right">{{mimeType}}</span>
  </div>
</template>
