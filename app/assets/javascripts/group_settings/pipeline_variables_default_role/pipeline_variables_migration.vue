<script>
import { GlButton, GlFormGroup, GlSprintf } from '@gitlab/ui';
import { createAlert } from '~/alert';
import { s__ } from '~/locale';
import safeDisablePipelineVariables from './graphql/mutations/safe_disable_pipeline_variables.mutation.graphql';

export default {
  name: 'PipelineVariablesMigration',
  components: { GlButton, GlFormGroup, GlSprintf },
  inject: ['fullPath'],
  data() {
    return {
      isSubmitting: false,
    };
  },
  methods: {
    async startMigration() {
      this.isSubmitting = true;
      try {
        const {
          data: {
            safeDisablePipelineVariables: { success, errors },
          },
        } = await this.$apollo.mutate({
          mutation: safeDisablePipelineVariables,
          variables: {
            fullPath: this.fullPath,
          },
        });

        if (errors.length) {
          createAlert({ message: errors[0].message });
        } else if (success) {
          this.$toast.show(
            s__(
              "CiVariables|Migration started. You'll receive an email notification after all projects have been migrated.",
            ),
          );
        }
      } catch (err) {
        createAlert({
          message: s__(
            'CiVariables|There was a problem starting the pipeline variables migration.',
          ),
        });
      }
      this.isSubmitting = false;
    },
  },
  i18n: {
    labelDescription: s__(
      'CiVariables|In all projects that do not use pipeline variables, change the %{strongStart}Minimum role to use pipeline variables%{strongEnd} setting to %{strongStart}No one allowed%{strongEnd}. Project owners can later choose a different setting if needed.',
    ),
  },
};
</script>

<template>
  <div class="gl-mb-5">
    <gl-form-group
      :label="s__('CiVariables|Disable pipeline variables in projects that don\'t use them')"
    >
      <template #label-description>
        <gl-sprintf :message="$options.i18n.labelDescription">
          <template #strong="{ content }">
            <strong>{{ content }}</strong>
          </template>
        </gl-sprintf>
      </template>
      <gl-button
        category="secondary"
        variant="confirm"
        class="gl-mt-3"
        :loading="isSubmitting"
        @click="startMigration"
      >
        {{ s__('CiVariables|Start migration') }}
      </gl-button>
    </gl-form-group>
  </div>
</template>
