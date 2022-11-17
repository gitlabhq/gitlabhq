<script>
import { GlAccordion, GlAccordionItem, GlAlert, GlForm, GlFormCheckbox } from '@gitlab/ui';

export default {
  components: {
    GlAccordion,
    GlAccordionItem,
    GlAlert,
    GlForm,
    GlFormCheckbox,
  },
  props: {
    stages: {
      required: true,
      type: Array,
    },
    value: {
      required: true,
      type: Object,
    },
    isInitiallyExpanded: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
};
</script>
<template>
  <gl-accordion :header-level="3">
    <gl-accordion-item
      :title="s__('ImportProjects|Advanced import settings')"
      :visible="isInitiallyExpanded"
    >
      <gl-alert variant="warning" class="gl-mb-5" :dismissible="false">{{
        s__('ImportProjects|The more information you select, the longer it will take to import')
      }}</gl-alert>
      <gl-form>
        <gl-form-checkbox
          v-for="{ name, label, details } in stages"
          :key="name"
          :checked="value[name]"
          :data-qa-option-name="name"
          data-qa-selector="advanced_settings_checkbox"
          @change="$emit('input', { ...value, [name]: $event })"
        >
          {{ label }}
          <template v-if="details" #help>{{ details }} </template>
        </gl-form-checkbox>
      </gl-form>
    </gl-accordion-item>
  </gl-accordion>
</template>
