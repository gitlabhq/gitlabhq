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
    type="button"
    class="btn btn-blank gutter-toggle btn-sidebar-action"
    @click="toggle"
    v-tooltip
    data-container="body"
    data-placement="left"
    :title="tooltipLabel"
  >
    <i
      aria-label="toggle collapse"
      class="fa"
      :class="{
        'fa-angle-double-right': !collapsed,
        'fa-angle-double-left': collapsed
      }"
    >
    </i>
  </button>
</template>
