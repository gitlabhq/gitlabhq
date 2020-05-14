<script>
import { mapActions } from 'vuex';
import PanelResizer from '~/vue_shared/components/panel_resizer.vue';

export default {
  components: {
    PanelResizer,
  },
  props: {
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
    ...mapActions(['setResizingStatus']),
  },
  maxSize: window.innerWidth / 2,
};
</script>

<template>
  <div :style="panelStyle" class="multi-file-commit-panel">
    <slot></slot>
    <panel-resizer
      :size.sync="width"
      :start-size="initialWidth"
      :min-size="minSize"
      :max-size="$options.maxSize"
      :side="side === 'right' ? 'left' : 'right'"
      @resize-start="setResizingStatus(true)"
      @resize-end="setResizingStatus(false)"
    />
  </div>
</template>
