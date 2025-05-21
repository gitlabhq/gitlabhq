<script>
import { GlFormGroup, GlFormInput, GlFormTextarea, GlSprintf } from '@gitlab/ui';

import FormUrlApp from './form_url_app.vue';
import FormCustomHeaders from './form_custom_headers.vue';

export default {
  components: {
    GlFormGroup,
    GlFormInput,
    GlFormTextarea,
    GlSprintf,
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
    initialSecretToken: {
      type: String,
      required: false,
      default: '',
    },
  },
  data() {
    return {
      name: this.initialName,
      description: this.initialDescription,
      secretToken: this.initialSecretToken,
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

    <gl-form-group :label="s__('Webhooks|Secret token')" label-for="webhook-secret-token">
      <template #description>
        <gl-sprintf
          :message="
            s__(
              'Webhooks|Used to validate received payloads. Sent with the request in the %{codeStart}X-Gitlab-Token%{codeEnd} HTTP header.',
            )
          "
        >
          <template #code="{ content }">
            <code>{{ content }}</code>
          </template>
        </gl-sprintf>
      </template>
      <gl-form-input
        id="webhook-secret-token"
        v-model="secretToken"
        name="hook[token]"
        type="password"
        autocomplete="new-password"
        class="gl-form-input-xl"
        data-testid="webhook-secret-token"
      />
    </gl-form-group>

    <form-custom-headers :initial-custom-headers="initialCustomHeaders" />
  </div>
</template>
