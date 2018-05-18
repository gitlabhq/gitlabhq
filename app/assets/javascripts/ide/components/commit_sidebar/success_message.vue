<script>
import { mapState } from 'vuex';

export default {
  computed: {
    ...mapState(['lastCommitMsg', 'committedStateSvgPath']),
  },
};
</script>

<template>
  <div
    class="multi-file-commit-panel-success-message"
    aria-live="assertive"
  >
    <div class="svg-content svg-80">
      <img
        :src="committedStateSvgPath"
        alt=""
      />
    </div>
    <div class="append-right-default prepend-left-default">
      <div
        class="text-content text-center"
      >
        <h4>
          {{ __('All changes are committed') }}
        </h4>
        <p v-html="lastCommitMsg"></p>
      </div>
    </div>
  </div>
</template>
