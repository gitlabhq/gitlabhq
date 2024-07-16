<script>
import { GlFormCheckbox } from '@gitlab/ui';

export default {
  name: 'LabelDropdownItems',
  components: {
    GlFormCheckbox,
  },
  props: {
    labels: {
      type: Array,
      required: true,
    },
  },
};
</script>
<template>
  <ul class="gl-list-none gl-px-0">
    <li
      v-for="label in labels"
      :id="label.key"
      :ref="label.key"
      :key="label.key"
      :aria-label="label.title"
      tabindex="-1"
      class="gl-px-5 gl-py-3 label-filter-menu-item"
    >
      <gl-form-checkbox
        class="label-with-color-checkbox gl-inline-flex gl-min-h-5"
        :value="label.key"
      >
        <span
          data-testid="label-color-indicator"
          class="gl-rounded-base gl-min-w-5 gl-h-5 gl-display-inline-block gl-align-bottom gl-mr-3"
          :style="{ 'background-color': label.color }"
        ></span>
        <span class="gl-text-align-inherit gl-m-0 gl-p-0 label-title gl-break-all">{{
          label.title
        }}</span></gl-form-checkbox
      >
    </li>
  </ul>
</template>
