<script>
import {
  GlFormGroup,
  GlFormInput,
  GlModal,
  GlTooltipDirective,
  GlLoadingIcon,
  GlSprintf,
  GlLink,
  GlIcon,
} from '@gitlab/ui';
import { s__, __ } from '~/locale';
import ModalCopyButton from '~/vue_shared/components/modal_copy_button.vue';
import Callout from '~/vue_shared/components/callout.vue';

export default {
  components: {
    GlFormGroup,
    GlFormInput,
    GlModal,
    ModalCopyButton,
    GlIcon,
    Callout,
    GlLoadingIcon,
    GlSprintf,
    GlLink,
  },

  directives: {
    GlTooltip: GlTooltipDirective,
  },

  props: {
    instanceId: {
      type: String,
      required: true,
    },
    modalId: {
      type: String,
      required: false,
      default: 'configure-feature-flags',
    },
    isRotating: {
      type: Boolean,
      required: true,
    },
    hasRotateError: {
      type: Boolean,
      required: true,
    },
    canUserRotateToken: {
      type: Boolean,
      required: true,
    },
  },
  inject: [
    'projectName',
    'featureFlagsHelpPagePath',
    'unleashApiUrl',
    'featureFlagsClientExampleHelpPagePath',
    'featureFlagsClientLibrariesHelpPagePath',
  ],
  translations: {
    cancelActionLabel: __('Close'),
    modalTitle: s__('FeatureFlags|Configure feature flags'),
    apiUrlLabelText: s__('FeatureFlags|API URL'),
    apiUrlCopyText: __('Copy URL'),
    instanceIdLabelText: s__('FeatureFlags|Instance ID'),
    instanceIdCopyText: __('Copy ID'),
    instanceIdRegenerateError: __('Unable to generate new instance ID'),
    instanceIdRegenerateText: __(
      'Regenerating the instance ID can break integration depending on the client you are using.',
    ),
    instanceIdRegenerateActionLabel: __('Regenerate instance ID'),
  },
  data() {
    return {
      enteredProjectName: '',
    };
  },
  computed: {
    cancelActionProps() {
      return {
        text: this.$options.translations.cancelActionLabel,
      };
    },
    canRegenerateInstanceId() {
      return this.canUserRotateToken && this.enteredProjectName === this.projectName;
    },
    regenerateInstanceIdActionProps() {
      return this.canUserRotateToken
        ? {
            text: this.$options.translations.instanceIdRegenerateActionLabel,
            attributes: [
              {
                category: 'secondary',
                disabled: !this.canRegenerateInstanceId,
                loading: this.isRotating,
                variant: 'danger',
              },
            ],
          }
        : null;
    },
  },

  methods: {
    clearState() {
      this.enteredProjectName = '';
    },
    rotateToken() {
      this.$emit('token');
      this.clearState();
    },
  },
};
</script>
<template>
  <gl-modal
    :modal-id="modalId"
    :action-cancel="cancelActionProps"
    :action-primary="regenerateInstanceIdActionProps"
    @canceled="clearState"
    @hide="clearState"
    @primary.prevent="rotateToken"
  >
    <template #modal-title>
      {{ $options.translations.modalTitle }}
    </template>
    <p>
      <gl-sprintf
        :message="
          s__(
            'FeatureFlags|Install a %{docsLinkAnchoredStart}compatible client library%{docsLinkAnchoredEnd} and specify the API URL, application name, and instance ID during the configuration setup. %{docsLinkStart}More Information%{docsLinkEnd}',
          )
        "
      >
        <template #docsLinkAnchored="{ content }">
          <gl-link
            :href="featureFlagsClientLibrariesHelpPagePath"
            target="_blank"
            data-testid="help-client-link"
          >
            {{ content }}
          </gl-link>
        </template>
        <template #docsLink="{ content }">
          <gl-link :href="featureFlagsHelpPagePath" target="_blank" data-testid="help-link">{{
            content
          }}</gl-link>
        </template>
      </gl-sprintf>
    </p>

    <callout category="warning">
      <gl-sprintf
        :message="
          s__(
            'FeatureFlags|Set the Unleash client application name to the name of the environment your application runs in. This value is used to match environment scopes. See the %{linkStart}example client configuration%{linkEnd}.',
          )
        "
      >
        <template #link="{ content }">
          <gl-link :href="featureFlagsClientExampleHelpPagePath" target="_blank">{{
            content
          }}</gl-link>
        </template>
      </gl-sprintf>
    </callout>
    <div class="form-group">
      <label for="api_url" class="label-bold">{{ $options.translations.apiUrlLabelText }}</label>
      <div class="input-group">
        <input
          id="api_url"
          :value="unleashApiUrl"
          readonly
          class="form-control"
          type="text"
          name="api_url"
        />
        <span class="input-group-append">
          <modal-copy-button
            :text="unleashApiUrl"
            :title="$options.translations.apiUrlCopyText"
            :modal-id="modalId"
            class="input-group-text"
          />
        </span>
      </div>
    </div>
    <div class="form-group">
      <label for="instance_id" class="label-bold">{{
        $options.translations.instanceIdLabelText
      }}</label>
      <div class="input-group">
        <input
          id="instance_id"
          :value="instanceId"
          class="form-control"
          type="text"
          name="instance_id"
          readonly
          :disabled="isRotating"
        />

        <gl-loading-icon
          v-if="isRotating"
          class="position-absolute align-self-center instance-id-loading-icon"
        />

        <div class="input-group-append">
          <modal-copy-button
            :text="instanceId"
            :title="$options.translations.instanceIdCopyText"
            :modal-id="modalId"
            :disabled="isRotating"
            class="input-group-text"
          />
        </div>
      </div>
    </div>
    <div
      v-if="hasRotateError"
      class="text-danger d-flex align-items-center font-weight-normal mb-2"
    >
      <gl-icon name="warning" class="mr-1" />
      <span>{{ $options.translations.instanceIdRegenerateError }}</span>
    </div>
    <callout
      v-if="canUserRotateToken"
      category="danger"
      :message="$options.translations.instanceIdRegenerateText"
    />
    <p v-if="canUserRotateToken" data-testid="prevent-accident-text">
      <gl-sprintf
        :message="
          s__(
            'FeatureFlags|To prevent accidental actions we ask you to confirm your intention. Please type %{projectName} to proceed or close this modal to cancel.',
          )
        "
      >
        <template #projectName>
          <span class="gl-font-weight-bold gl-text-red-500">{{ projectName }}</span>
        </template>
      </gl-sprintf>
    </p>
    <gl-form-group>
      <gl-form-input
        v-if="canUserRotateToken"
        id="project_name_verification"
        v-model="enteredProjectName"
        name="project_name"
        type="text"
        :disabled="isRotating"
      />
    </gl-form-group>
  </gl-modal>
</template>
