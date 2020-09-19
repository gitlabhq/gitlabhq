<script>
/* eslint-disable vue/no-v-html */
import { mapState } from 'vuex';

export default {
  computed: {
    ...mapState(['lastCommitMsg', 'committedStateSvgPath']),
  },
};
</script>

<template>
  <div class="multi-file-commit-panel-success-message" aria-live="assertive">
    <div class="svg-content svg-80">
      <img :src="committedStateSvgPath" :alt="s__('IDE|Successful commit')" />
    </div>
    <div class="gl-mr-3 gl-ml-3">
      <div class="text-content text-center">
        <h4>{{ __('All changes are committed') }}</h4>
        <p v-html="lastCommitMsg"></p>
      </div>
    </div>
  </div>
</template>
