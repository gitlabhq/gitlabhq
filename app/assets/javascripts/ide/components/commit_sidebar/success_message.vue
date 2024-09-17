<script>
// eslint-disable-next-line no-restricted-imports
import { mapState } from 'vuex';
import SafeHtml from '~/vue_shared/directives/safe_html';

export default {
  directives: {
    SafeHtml,
  },
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
    <div class="gl-ml-3 gl-mr-3">
      <div class="text-content text-center">
        <h4>{{ __('All changes are committed') }}</h4>
        <p v-safe-html="lastCommitMsg"></p>
      </div>
    </div>
  </div>
</template>
