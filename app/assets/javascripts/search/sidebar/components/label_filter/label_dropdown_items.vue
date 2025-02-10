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
      data-testid="label-filter-menu-item"
      class="label-filter-menu-item gl-px-5 gl-py-3"
    >
      <gl-form-checkbox
        v-model="label.checked"
        class="label-with-color-checkbox gl-inline-flex gl-min-h-5"
        :value="label.key"
      >
        <span
          data-testid="label-color-indicator"
          class="gl-mr-3 gl-inline-block gl-h-5 gl-min-w-5 gl-rounded-base gl-align-bottom"
          :style="{ 'background-color': label.color }"
        ></span>
        <span class="label-title gl-m-0 gl-break-all gl-p-0 gl-text-align-inherit">{{
          label.title
        }}</span></gl-form-checkbox
      >
    </li>
  </ul>
</template>
