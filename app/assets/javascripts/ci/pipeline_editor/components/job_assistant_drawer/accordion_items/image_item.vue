<script>
import { GlFormGroup, GlAccordionItem, GlFormInput, GlFormTextarea } from '@gitlab/ui';
import { i18n } from '../constants';

export default {
  i18n,
  placeholderText: i18n.ENTRYPOINT_PLACEHOLDER_TEXT,
  components: {
    GlAccordionItem,
    GlFormInput,
    GlFormTextarea,
    GlFormGroup,
  },
  props: {
    job: {
      type: Object,
      required: true,
    },
  },
  computed: {
    imageEntryPoint() {
      return this.job.image.entrypoint.join('\n');
    },
  },
};
</script>
<template>
  <gl-accordion-item :title="$options.i18n.IMAGE">
    <gl-form-group :label="$options.i18n.IMAGE_NAME">
      <gl-form-input
        :value="job.image.name"
        data-testid="image-name-input"
        @input="$emit('update-job', 'image.name', $event)"
      />
    </gl-form-group>
    <gl-form-group
      :label="$options.i18n.IMAGE_ENTRYPOINT"
      :description="$options.i18n.ARRAY_FIELD_DESCRIPTION"
      class="gl-mb-0"
    >
      <gl-form-textarea
        :no-resize="false"
        :placeholder="$options.placeholderText"
        data-testid="image-entrypoint-input"
        :value="imageEntryPoint"
        @input="$emit('update-job', 'image.entrypoint', $event.split('\n'))"
      />
    </gl-form-group>
  </gl-accordion-item>
</template>
