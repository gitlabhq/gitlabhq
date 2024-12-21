<script>
import { GlFormGroup, GlButton, GlFormInput } from '@gitlab/ui';
import { s__, __ } from '~/locale';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import addNamespaceMutation from '../graphql/mutations/inbound_add_group_or_project_ci_job_token_scope.mutation.graphql';
import editNamespaceMutation from '../graphql/mutations/edit_namespace_job_token_scope.mutation.graphql';
import PoliciesSelector from './policies_selector.vue';

export default {
  components: { GlFormGroup, GlButton, GlFormInput, PoliciesSelector },
  mixins: [glFeatureFlagsMixin()],
  inject: ['fullPath'],
  props: {
    namespace: {
      type: Object,
      required: false,
      default: null,
    },
  },
  data() {
    return {
      targetPath: '',
      defaultPermissions: true,
      jobTokenPolicies: [],
      errorMessage: '',
      isSaving: false,
    };
  },
  computed: {
    isPathInputDisabled() {
      // Disable the path if the form is currently saving or if we're editing a namespace.
      return this.isSaving || Boolean(this.namespace);
    },
    saveButtonText() {
      return this.namespace ? __('Save') : __('Add');
    },
  },
  watch: {
    namespace: {
      immediate: true,
      handler() {
        // Update the local data when the namespace changes. This will happen if the form is open and
        // the user tries to edit another namespace.
        this.targetPath = this.namespace?.fullPath ?? '';
        this.defaultPermissions = this.namespace?.defaultPermissions ?? true;
        this.jobTokenPolicies = this.namespace?.jobTokenPolicies ?? [];
      },
    },
  },
  methods: {
    async saveNamespace() {
      try {
        this.isSaving = true;
        this.errorMessage = '';

        const variables = { projectPath: this.fullPath, targetPath: this.targetPath };

        if (this.glFeatures.addPoliciesToCiJobToken) {
          variables.defaultPermissions = this.defaultPermissions;
          variables.jobTokenPolicies = this.defaultPermissions ? [] : this.jobTokenPolicies;
        }

        const mutation = this.namespace ? editNamespaceMutation : addNamespaceMutation;
        const response = await this.$apollo.mutate({ mutation, variables });

        const error = response.data.saveNamespace.errors[0];
        if (error) {
          this.errorMessage = error;
        } else {
          this.$emit('saved');
          this.$emit('close');
        }
      } catch ({ message }) {
        this.errorMessage = message;
      } finally {
        this.isSaving = false;
      }
    },
  },
  i18n: {
    groupOrProjectDescription: s__(
      'CICD|Paste a group or project path to authorize access into this project.',
    ),
  },
};
</script>

<template>
  <div>
    <gl-form-group
      label-for="namespace-input"
      :label="s__('CICD|Group or project')"
      :state="!errorMessage"
      :label-description="$options.i18n.groupOrProjectDescription"
      :invalid-feedback="errorMessage"
    >
      <gl-form-input
        id="namespace-input"
        v-model.trim="targetPath"
        autofocus
        :state="!errorMessage"
        :placeholder="fullPath"
        :disabled="isPathInputDisabled"
        @input="errorMessage = ''"
      />
    </gl-form-group>

    <policies-selector
      v-if="glFeatures.addPoliciesToCiJobToken"
      :is-default-permissions-selected="defaultPermissions"
      :job-token-policies="jobTokenPolicies"
      :disabled="isSaving"
      class="gl-mb-6"
      @update:isDefaultPermissionsSelected="defaultPermissions = $event"
      @update:jobTokenPolicies="jobTokenPolicies = $event"
    />

    <gl-button
      variant="confirm"
      :disabled="!targetPath"
      :loading="isSaving"
      data-testid="submit-button"
      @click="saveNamespace"
    >
      {{ saveButtonText }}
    </gl-button>
    <gl-button
      class="gl-ml-3"
      :disabled="isSaving"
      data-testid="cancel-button"
      @click="$emit('close')"
    >
      {{ __('Cancel') }}
    </gl-button>
  </div>
</template>
