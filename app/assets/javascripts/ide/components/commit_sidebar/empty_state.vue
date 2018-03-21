<script>
import { mapActions, mapState, mapGetters } from 'vuex';
import Icon from '~/vue_shared/components/icon.vue';

export default {
  components: {
    Icon,
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
    ...mapState(['lastCommitMsg', 'rightPanelCollapsed']),
    ...mapGetters(['collapseButtonIcon']),
    statusSvg() {
      return this.lastCommitMsg
        ? this.committedStateSvgPath
        : this.noChangesStateSvgPath;
    },
  },
  methods: {
    ...mapActions(['toggleRightPanelCollapsed']),
  },
};
</script>

<template>
  <div
    class="multi-file-commit-panel-section ide-commity-empty-state js-empty-state"
  >
    <header
      class="multi-file-commit-panel-header"
      :class="{
        'is-collapsed': rightPanelCollapsed,
      }"
    >
      <button
        type="button"
        class="btn btn-transparent multi-file-commit-panel-collapse-btn"
        :aria-label="__('Toggle sidebar')"
        @click.stop="toggleRightPanelCollapsed"
      >
        <icon
          :name="collapseButtonIcon"
          :size="18"
        />
      </button>
    </header>
    <div
      class="ide-commit-empty-state-container"
      v-if="!rightPanelCollapsed"
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
