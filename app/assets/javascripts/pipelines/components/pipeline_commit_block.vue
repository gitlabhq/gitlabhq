<script>
  export default {
    name: 'pipelineCommitBlocl',
    props: {
      commit: {
        type: Object,
        required: true
      },
    },
  };
</script>
<template>
  <div class="commit-box">
    <h3 class="commit-title">
      {{commit.title}}
    </h3>
    <pre
      v-if="commit.description"
      class="commit-description">
      {{commit.description}}
    </pre>
  </div>
</template>
