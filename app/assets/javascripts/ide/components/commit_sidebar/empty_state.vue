<script>
// eslint-disable-next-line no-restricted-imports
import { mapState } from 'vuex';

export default {
  computed: {
    ...mapState(['lastCommitMsg', 'noChangesStateSvgPath']),
  },
};
</script>

<template>
  <div v-if="!lastCommitMsg" class="multi-file-commit-panel-section ide-commit-empty-state">
    <div class="ide-commit-empty-state-container">
      <div class="svg-content svg-80"><img :src="noChangesStateSvgPath" /></div>
      <div class="gl-ml-3 gl-mr-3">
        <div class="text-content text-center">
          <h4>{{ __('No changes') }}</h4>
          <p>{{ __('Edit files in the editor and commit changes here') }}</p>
        </div>
      </div>
    </div>
  </div>
</template>
