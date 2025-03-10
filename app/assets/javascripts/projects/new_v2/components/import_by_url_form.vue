<script>
import { GlButton } from '@gitlab/ui';
import MultiStepFormTemplate from '~/vue_shared/components/multi_step_form_template.vue';

export default {
  components: {
    GlButton,
    MultiStepFormTemplate,
  },
};
</script>

<template>
  <multi-step-form-template
    :title="s__('ProjectImport|Import repository by URL')"
    :current-step="3"
  >
    <template #next>
      <gl-button
        category="primary"
        variant="confirm"
        :disabled="true"
        data-testid="import-project-by-url-next-button"
      >
        {{ __('Next step') }}
      </gl-button>
    </template>
    <template #back>
      <gl-button
        category="primary"
        variant="default"
        data-testid="import-project-by-url-back-button"
        @click="$emit('back')"
      >
        {{ __('Go back') }}
      </gl-button>
    </template>
  </multi-step-form-template>
</template>
