<script>
import { __ } from '~/locale';
import tooltip from '~/vue_shared/directives/tooltip';

export default {
  name: 'ToggleSidebar',
  directives: {
    tooltip,
  },
  props: {
    collapsed: {
      type: Boolean,
      required: true,
    },
    cssClasses: {
      type: String,
      required: false,
      default: '',
    },
  },
  computed: {
    tooltipLabel() {
      return this.collapsed ? __('Expand sidebar') : __('Collapse sidebar');
    },
  },
  methods: {
    toggle() {
      this.$emit('toggle');
    },
  },
};
</script>

<template>
  <button
    v-tooltip
    :title="tooltipLabel"
    :class="cssClasses"
    type="button"
    class="btn btn-blank gutter-toggle btn-sidebar-action"
    data-container="body"
    data-placement="left"
    data-boundary="viewport"
    @click="toggle"
  >
    <i
      :class="{
        'fa-angle-double-right': !collapsed,
        'fa-angle-double-left': collapsed
      }"
      aria-label="toggle collapse"
      class="fa"
    >
    </i>
  </button>
</template>
