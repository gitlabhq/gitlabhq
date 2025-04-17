<script>
import { GlFormGroup, GlFormInput, GlFormTextarea } from '@gitlab/ui';

import FormUrlApp from './form_url_app.vue';
import FormCustomHeaders from './form_custom_headers.vue';

export default {
  components: {
    GlFormGroup,
    GlFormInput,
    GlFormTextarea,
    FormUrlApp,
    FormCustomHeaders,
  },
  props: {
    initialUrl: {
      type: String,
      required: false,
      default: null,
    },
    initialUrlVariables: {
      type: Array,
      required: false,
      default: () => [],
    },
    initialCustomHeaders: {
      type: Array,
      required: false,
      default: () => [],
    },
    initialName: {
      type: String,
      required: false,
      default: '',
    },
    initialDescription: {
      type: String,
      required: false,
      default: '',
    },
  },
  data() {
    return {
      name: this.initialName,
      description: this.initialDescription,
    };
  },
};
</script>

<template>
  <div>
    <gl-form-group :label="s__('Webhooks|Name (optional)')" label-for="webhook-name">
      <gl-form-input
        id="webhook-name"
        v-model="name"
        name="hook[name]"
        class="gl-form-input-xl"
        data-testid="webhook-name"
      />
    </gl-form-group>

    <gl-form-group :label="s__('Webhooks|Description (optional)')" label-for="webhook-description">
      <gl-form-textarea
        id="webhook-description"
        v-model="description"
        name="hook[description]"
        class="gl-form-input-xl"
        rows="4"
        maxlength="2048"
        data-testid="webhook-description"
      />
    </gl-form-group>

    <form-url-app :initial-url="initialUrl" :initial-url-variables="initialUrlVariables" />
    <form-custom-headers :initial-custom-headers="initialCustomHeaders" />
  </div>
</template>
