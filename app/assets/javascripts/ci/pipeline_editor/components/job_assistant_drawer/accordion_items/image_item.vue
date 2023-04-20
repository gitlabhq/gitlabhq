<script>
import { GlFormGroup, GlAccordionItem, GlFormInput } from '@gitlab/ui';
import { i18n } from '../constants';

export default {
  i18n,
  components: {
    GlAccordionItem,
    GlFormInput,
    GlFormGroup,
  },
  props: {
    job: {
      type: Object,
      required: true,
    },
  },
};
</script>
<template>
  <gl-accordion-item :title="$options.i18n.IMAGE">
    <div class="gl-display-flex">
      <gl-form-group
        class="gl-flex-grow-1 gl-flex-basis-half gl-mr-3"
        :label="$options.i18n.IMAGE_NAME"
      >
        <gl-form-input
          :value="job.image.name"
          data-testid="image-name-input"
          @input="$emit('update-job', 'image.name', $event)"
        />
      </gl-form-group>
      <gl-form-group
        class="gl-flex-grow-1 gl-flex-basis-half"
        :label="$options.i18n.IMAGE_ENTRYPOINT"
      >
        <gl-form-input
          :value="job.image.entrypoint.join(' ')"
          data-testid="image-entrypoint-input"
          @input="$emit('update-job', 'image.entrypoint', $event.split(' '))"
        />
      </gl-form-group>
    </div>
  </gl-accordion-item>
</template>
