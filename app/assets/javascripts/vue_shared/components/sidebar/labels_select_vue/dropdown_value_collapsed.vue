<script>
import { GlIcon, GlTooltipDirective } from '@gitlab/ui';
import { s__, sprintf } from '~/locale';

// @deprecated This component should only be used when there is no GraphQL API.
// In most cases you should use
// `app/assets/javascripts/sidebar/components/labels/labels_select_widget` instead.
export default {
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  components: {
    GlIcon,
  },
  props: {
    labels: {
      type: Array,
      required: true,
    },
  },
  computed: {
    labelsList() {
      const labelsString = this.labels.length
        ? this.labels
            .slice(0, 5)
            .map((label) => label.title)
            .join(', ')
        : s__('LabelSelect|Labels');

      if (this.labels.length > 5) {
        return sprintf(s__('LabelSelect|%{labelsString}, and %{remainingLabelCount} more'), {
          labelsString,
          remainingLabelCount: this.labels.length - 5,
        });
      }

      return labelsString;
    },
  },
  methods: {
    handleClick() {
      this.$emit('onValueClick');
    },
  },
};
</script>

<template>
  <div v-gl-tooltip.left.viewport="labelsList" class="sidebar-collapsed-icon" @click="handleClick">
    <gl-icon name="labels" />
    <span>{{ labels.length }}</span>
  </div>
</template>
