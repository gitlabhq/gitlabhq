<script>
import { MountingPortal } from 'portal-vue';
import { uniqueId } from 'lodash-es';

export default {
  name: 'PanelActionsPortal',
  components: {
    MountingPortal,
  },
  data() {
    return {
      resolvedSelector: null,
    };
  },
  mounted() {
    const panelView = this.$el.closest(this.$options.panelSelector);
    if (!panelView) return;

    const target = panelView.querySelector(this.$options.targetSelector);
    if (!target) return;

    if (!target.id) {
      target.id = uniqueId('panel-actions-portal-target-');
    }

    this.resolvedSelector = `#${target.id}`;
  },
  panelSelector: '.js-paneled-view',
  targetSelector: '.js-panel-actions-portal-target',
};
</script>

<template>
  <mounting-portal v-if="resolvedSelector" :mount-to="resolvedSelector" append>
    <slot></slot>
  </mounting-portal>
  <div v-else hidden></div>
</template>
