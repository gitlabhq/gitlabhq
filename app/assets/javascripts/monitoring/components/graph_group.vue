<script>
import Icon from '~/vue_shared/components/icon.vue';

export default {
  components: {
    Icon,
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
    collapseGroup: {
      type: Boolean,
      required: true,
    },
  },
  data() {
    return {
      showGroup: true,
    };
  },
  computed: {
    caretIcon() {
      return this.collapseGroup && this.showGroup ? 'angle-down' : 'angle-right';
    },
  },
  methods: {
    collapse() {
      this.showGroup = !this.showGroup;
    },
  },
};
</script>

<template>
  <div v-if="showPanels" class="card prometheus-panel">
    <div class="card-header d-flex align-items-center">
      <h4 class="flex-grow-1">{{ name }}</h4>
      <a role="button" class="js-graph-group-toggle" @click="collapse">
        <icon :size="16" :aria-label="__('Toggle collapse')" :name="caretIcon" />
      </a>
    </div>
    <div
      v-if="collapseGroup"
      v-show="collapseGroup && showGroup"
      class="card-body prometheus-graph-group p-0"
    >
      <slot></slot>
    </div>
  </div>
  <div v-else class="prometheus-graph-group"><slot></slot></div>
</template>
