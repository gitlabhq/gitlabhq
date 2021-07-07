<script>
import { GlLoadingIcon, GlIcon } from '@gitlab/ui';

export default {
  components: {
    GlLoadingIcon,
    GlIcon,
  },
  props: {
    name: {
      type: String,
      required: true,
    },
    showPanels: {
      type: Boolean,
      required: false,
      default: true,
    },
    isLoading: {
      type: Boolean,
      required: false,
      default: false,
    },
    /**
     * Initial value of collapse on mount.
     */
    collapseGroup: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  data() {
    return {
      isCollapsed: this.collapseGroup,
    };
  },
  computed: {
    caretIcon() {
      return this.isCollapsed ? 'angle-right' : 'angle-down';
    },
  },
  watch: {
    collapseGroup(val) {
      // Respond to changes in collapseGroup but do not
      // collapse it once was opened by the user.
      if (this.showPanels && !val) {
        this.isCollapsed = false;
      }
    },
  },
  methods: {
    collapse() {
      this.isCollapsed = !this.isCollapsed;
    },
  },
};
</script>

<template>
  <div v-if="showPanels" ref="graph-group" class="card prometheus-panel">
    <div class="card-header d-flex align-items-center">
      <h4 class="flex-grow-1">{{ name }}</h4>
      <gl-loading-icon v-if="isLoading" size="sm" name="loading" />
      <a
        data-testid="group-toggle-button"
        :aria-label="__('Toggle collapse')"
        :icon="caretIcon"
        role="button"
        class="js-graph-group-toggle gl-display-flex gl-ml-2 gl-text-gray-900"
        tabindex="0"
        @click="collapse"
        @keyup.enter="collapse"
      >
        <gl-icon :name="caretIcon" />
      </a>
    </div>
    <div
      v-show="!isCollapsed"
      ref="graph-group-content"
      class="card-body prometheus-graph-group p-0"
    >
      <slot></slot>
    </div>
  </div>
  <div v-else ref="graph-group-content" class="prometheus-graph-group"><slot></slot></div>
</template>
