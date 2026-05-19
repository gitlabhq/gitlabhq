<script>
import { GlAlert, GlFormGroup, GlFormInput, GlFormTextarea, GlLink, GlSprintf } from '@gitlab/ui';
import glFeatureFlagMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';

import FormUrlApp from './form_url_app.vue';
import FormCustomHeaders from './form_custom_headers.vue';
import WebhookFormTriggerList from './webhook_form_trigger_list.vue';
import WebhookTokenInput from './webhook_token_input.vue';

export default {
  name: 'WebhookFormApp',
  components: {
    GlAlert,
    GlFormGroup,
    GlFormInput,
    GlFormTextarea,
    GlLink,
    GlSprintf,
    FormUrlApp,
    FormCustomHeaders,
    WebhookFormTriggerList,
    WebhookTokenInput,
  },
  mixins: [glFeatureFlagMixin()],
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
    hasSigningToken: {
      type: Boolean,
      required: false,
      default: false,
    },
    signingTokenDocsPath: {
      type: String,
      required: false,
      default: '',
    },
    initialTriggers: {
      type: Object,
      required: true,
    },
    hasGroup: {
      type: Boolean,
      required: false,
      default: false,
    },
    isSystemHook: {
      type: Boolean,
      required: false,
      default: false,
    },
    isNewHook: {
      type: Boolean,
      required: false,
      default: false,
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
    <gl-alert
      v-if="glFeatures.webhookSigningToken && initialSecretToken"
      variant="warning"
      :dismissible="false"
      class="gl-mb-5"
      data-testid="secret-token-not-recommended-alert"
    >
      <gl-sprintf
        :message="
          s__(
            'Webhooks|This hook uses a secret token, which is not recommended. %{linkStart}Switch to the more secure signing token%{linkEnd}.',
          )
        "
      >
        <template #link="{ content }">
          <gl-link :href="signingTokenDocsPath" target="_blank">{{ content }}</gl-link>
        </template>
      </gl-sprintf>
    </gl-alert>

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

    <form-url-app
      :initial-url="initialUrl"
      :initial-url-variables="initialUrlVariables"
      :initial-secret-token="initialSecretToken"
    />

    <webhook-token-input
      v-if="glFeatures.webhookSigningToken"
      :has-existing-token="hasSigningToken"
      :docs-path="signingTokenDocsPath"
      input-name="hook[signing_token]"
    />

    <gl-form-group
      :label="
        glFeatures.webhookSigningToken
          ? s__('Webhooks|Secret token (not recommended)')
          : s__('Webhooks|Secret token')
      "
      label-for="webhook-secret-token"
    >
      <template #description>
        <gl-sprintf
          :message="
            s__(
              'Webhooks|Used to validate requests from GitLab. Sent in the %{codeStart}X-Gitlab-Token%{codeEnd} HTTP header.',
            )
          "
        >
          <template #code="{ content }">
            <code>{{ content }}</code>
          </template>
        </gl-sprintf>
        <template v-if="glFeatures.webhookSigningToken">
          {{ ' ' + s__('Webhooks|Signing tokens are more secure.') }}
        </template>
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

    <webhook-form-trigger-list
      :initial-triggers="initialTriggers"
      :has-group="hasGroup"
      :is-system-hook="isSystemHook"
      :is-new-hook="isNewHook"
    />

    <form-custom-headers :initial-custom-headers="initialCustomHeaders" />
  </div>
</template>
