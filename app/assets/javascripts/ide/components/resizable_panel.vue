<script>
import { mapActions, mapState } from 'vuex';
import PanelResizer from '~/vue_shared/components/panel_resizer.vue';

export default {
  components: {
    PanelResizer,
  },
  props: {
    collapsible: {
      type: Boolean,
      required: true,
    },
    initialWidth: {
      type: Number,
      required: true,
    },
    minSize: {
      type: Number,
      required: false,
      default: 340,
    },
    side: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      width: this.initialWidth,
    };
  },
  computed: {
    ...mapState({
      collapsed(state) {
        return state[`${this.side}PanelCollapsed`];
      },
    }),
    panelStyle() {
      if (!this.collapsed) {
        return {
          width: `${this.width}px`,
        };
      }

      return {};
    },
  },
  methods: {
    ...mapActions(['setPanelCollapsedStatus', 'setResizingStatus']),
    toggleFullbarCollapsed() {
      if (this.collapsed && this.collapsible) {
        this.setPanelCollapsedStatus({
          side: this.side,
          collapsed: !this.collapsed,
        });
      }
    },
  },
  maxSize: window.innerWidth / 2,
};
</script>

<template>
  <div
    class="multi-file-commit-panel"
    :class="{
      'is-collapsed': collapsed && collapsible,
    }"
    :style="panelStyle"
    @click="toggleFullbarCollapsed"
  >
    <slot></slot>
    <panel-resizer
      :size.sync="width"
      :enabled="!collapsed"
      :start-size="initialWidth"
      :min-size="minSize"
      :max-size="$options.maxSize"
      @resize-start="setResizingStatus(true)"
      @resize-end="setResizingStatus(false)"
      :side="side === 'right' ? 'left' : 'right'"
    />
  </div>
</template>
