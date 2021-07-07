<script>
import {
  GlFormGroup,
  GlFormInput,
  GlFormInputGroup,
  GlModal,
  GlTooltipDirective,
  GlLoadingIcon,
  GlSprintf,
  GlLink,
  GlIcon,
  GlAlert,
} from '@gitlab/ui';
import { s__, __ } from '~/locale';
import ModalCopyButton from '~/vue_shared/components/modal_copy_button.vue';

export default {
  components: {
    GlFormGroup,
    GlFormInput,
    GlFormInputGroup,
    GlModal,
    ModalCopyButton,
    GlIcon,
    GlLoadingIcon,
    GlSprintf,
    GlLink,
    GlAlert,
  },

  directives: {
    GlTooltip: GlTooltipDirective,
  },
  inject: [
    'projectName',
    'featureFlagsHelpPagePath',
    'unleashApiUrl',
    'featureFlagsClientExampleHelpPagePath',
    'featureFlagsClientLibrariesHelpPagePath',
  ],

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
        attributes: [
          {
            category: 'secondary',
          },
        ],
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
    :action-primary="cancelActionProps"
    :action-secondary="regenerateInstanceIdActionProps"
    @secondary.prevent="rotateToken"
    @hide="clearState"
    @primary="clearState"
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
    <gl-alert variant="warning" class="gl-mb-5" :dismissible="false">
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
    </gl-alert>
    <gl-form-group :label="$options.translations.apiUrlLabelText" label-for="api-url">
      <gl-form-input-group id="api-url" :value="unleashApiUrl" readonly type="text" name="api-url">
        <template #append>
          <modal-copy-button
            :text="unleashApiUrl"
            :title="$options.translations.apiUrlCopyText"
            :modal-id="modalId"
          />
        </template>
      </gl-form-input-group>
    </gl-form-group>
    <gl-form-group :label="$options.translations.instanceIdLabelText" label-for="instance_id">
      <gl-form-input-group>
        <gl-form-input
          id="instance_id"
          :value="instanceId"
          type="text"
          name="instance_id"
          readonly
          :disabled="isRotating"
        />
        <gl-loading-icon
          v-if="isRotating"
          size="sm"
          class="gl-absolute gl-align-self-center gl-right-5 gl-mr-7"
        />

        <template #append>
          <modal-copy-button
            :text="instanceId"
            :title="$options.translations.instanceIdCopyText"
            :modal-id="modalId"
            :disabled="isRotating"
          />
        </template>
      </gl-form-input-group>
    </gl-form-group>
    <div
      v-if="hasRotateError"
      class="gl-text-red-500 gl-display-flex gl-align-items-center gl-font-weight-normal gl-mb-3"
    >
      <gl-icon name="warning" class="gl-mr-2" />
      <span>{{ $options.translations.instanceIdRegenerateError }}</span>
    </div>
    <gl-alert v-if="canUserRotateToken" variant="danger" class="gl-mb-5" :dismissible="false">
      {{ $options.translations.instanceIdRegenerateText }}
    </gl-alert>
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
