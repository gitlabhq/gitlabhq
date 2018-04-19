<script>
import { mapState } from 'vuex';
import Icon from '~/vue_shared/components/icon.vue';
import tooltip from '~/vue_shared/directives/tooltip';

export default {
  components: {
    Icon,
  },
  directives: {
    tooltip,
  },
  props: {
    noChangesStateSvgPath: {
      type: String,
      required: true,
    },
    committedStateSvgPath: {
      type: String,
      required: true,
    },
  },
  computed: {
    ...mapState(['lastCommitMsg']),
    statusSvg() {
      return this.lastCommitMsg ? this.committedStateSvgPath : this.noChangesStateSvgPath;
    },
  },
};
</script>

<template>
  <div
    class="multi-file-commit-panel-section ide-commit-empty-state js-empty-state"
  >
    <div
      class="ide-commit-empty-state-container"
    >
      <div class="svg-content svg-80">
        <img :src="statusSvg" />
      </div>
      <div class="append-right-default prepend-left-default">
        <div
          class="text-content text-center"
          v-if="!lastCommitMsg"
        >
          <h4>
            {{ __('No changes') }}
          </h4>
          <p>
            {{ __('Edit files in the editor and commit changes here') }}
          </p>
        </div>
        <div
          class="text-content text-center"
          v-else
        >
          <h4>
            {{ __('All changes are committed') }}
          </h4>
          <p v-html="lastCommitMsg"></p>
        </div>
      </div>
    </div>
  </div>
</template>
