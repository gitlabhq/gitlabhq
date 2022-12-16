<script>
import { GlButton, GlTooltipDirective } from '@gitlab/ui';

export default {
  name: 'SourceEditorToolbarButton',
  components: {
    GlButton,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  props: {
    button: {
      type: Object,
      required: false,
      default() {
        return {};
      },
    },
  },
  computed: {
    icon() {
      return this.button.selected ? this.button.selectedIcon || this.button.icon : this.button.icon;
    },
    label() {
      return this.button.selected
        ? this.button.selectedLabel || this.button.label
        : this.button.label;
    },
    showButton() {
      return Object.entries(this.button).length > 0;
    },
  },
  mounted() {
    if (this.button.data) {
      Object.entries(this.button.data).forEach(([attr, value]) => {
        this.$el.dataset[attr] = value;
      });
    }
  },
  methods: {
    clickHandler(event) {
      if (this.button.onClick) {
        this.button.onClick(event);
      }
      this.$emit('click', event);
    },
  },
};
</script>
<template>
  <gl-button
    v-if="showButton"
    v-gl-tooltip.hover
    :category="button.category"
    :variant="button.variant"
    type="button"
    :selected="button.selected"
    :icon="icon"
    :title="label"
    :aria-label="label"
    :class="button.class"
    @click="clickHandler($event)"
  />
</template>
