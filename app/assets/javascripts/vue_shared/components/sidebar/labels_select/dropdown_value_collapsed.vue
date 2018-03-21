<script>
import { s__, sprintf } from '~/locale';
import tooltip from '~/vue_shared/directives/tooltip';

export default {
  directives: {
    tooltip,
  },
  props: {
    labels: {
      type: Array,
      required: true,
    },
  },
  computed: {
    labelsList() {
      const labelsString = this.labels.slice(0, 5).map(label => label.title).join(', ');

      if (this.labels.length > 5) {
        return sprintf(s__('LabelSelect|%{labelsString}, and %{remainingLabelCount} more'), {
          labelsString,
          remainingLabelCount: this.labels.length - 5,
        });
      }

      return labelsString;
    },
  },
};
</script>

<template>
  <div
    v-tooltip
    class="sidebar-collapsed-icon"
    data-placement="left"
    data-container="body"
    :title="labelsList"
  >
    <i
      aria-hidden="true"
      data-hidden="true"
      class="fa fa-tags"
    >
    </i>
    <span>{{ labels.length }}</span>
  </div>
</template>
