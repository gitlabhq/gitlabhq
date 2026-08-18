<script>
import { MountingPortal } from 'portal-vue';
import { uniqueId } from 'lodash-es';
import { glSlotsMixin } from '~/lib/utils/vue3compat/gl_slots_mixin';

export default {
  name: 'PanelActionsPortal',
  components: {
    MountingPortal,
  },
  mixins: [glSlotsMixin],
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
    <template v-if="glSlots().default" #default><slot></slot></template>
  </mounting-portal>
  <div v-else hidden></div>
</template>
