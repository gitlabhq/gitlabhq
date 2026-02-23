<script>
import { GlButton } from '@gitlab/ui';
import { GlTooltipDirective } from '@gitlab/ui/src/directives/tooltip/tooltip';

export default {
  name: 'VIfElseWithDirective',
  components: { GlButton },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  data() {
    return {
      count: 1,
    };
  },
  computed: {
    items() {
      return Array.from({ length: this.count }, (_, i) => ({
        id: i + 1,
        removable: this.count > 1,
      }));
    },
  },
  methods: {
    addItem() {
      this.count += 1;
    },
  },
};
</script>
<template>
  <div>
    <div v-for="(item, index) in items" :key="item.id" :data-testid="`row-${index}`">
      <gl-button
        v-if="item.removable"
        v-gl-tooltip
        :title="__('Remove')"
        data-testid="remove-btn"
        icon="remove"
      />
      <gl-button v-else data-testid="placeholder-btn" icon="remove" />
    </div>
    <button data-testid="add-btn" @click="addItem">{{ __('Add') }}</button>
  </div>
</template>
