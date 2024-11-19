<script>
import { GlFormGroup, GlButton, GlFormInput } from '@gitlab/ui';
import { s__ } from '~/locale';
import addNamespaceMutation from '../graphql/mutations/inbound_add_group_or_project_ci_job_token_scope.mutation.graphql';

export default {
  components: { GlFormGroup, GlButton, GlFormInput },
  inject: ['fullPath'],
  data() {
    return {
      namespacePath: '',
      errorMessage: '',
      isSaving: false,
    };
  },
  methods: {
    async saveNamespace() {
      try {
        this.isSaving = true;
        this.errorMessage = '';

        const response = await this.$apollo.mutate({
          mutation: addNamespaceMutation,
          variables: { projectPath: this.fullPath, targetPath: this.namespacePath },
        });

        const error = response.data.ciJobTokenScopeAddGroupOrProject.errors[0];
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
        v-model.trim="namespacePath"
        autofocus
        :state="!errorMessage"
        :placeholder="fullPath"
        :disabled="isSaving"
        @input="errorMessage = ''"
      />
    </gl-form-group>

    <gl-button
      variant="confirm"
      :disabled="!namespacePath"
      :loading="isSaving"
      data-testid="add-button"
      @click="saveNamespace"
    >
      {{ __('Add') }}
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
