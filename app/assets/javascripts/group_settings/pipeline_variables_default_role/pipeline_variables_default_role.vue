<script>
import { GlButton, GlFormGroup, GlFormRadio, GlFormRadioGroup, GlLink } from '@gitlab/ui';
import { helpPagePath } from '~/helpers/help_page_helper';
import { createAlert } from '~/alert';
import { __, s__ } from '~/locale';
import { reportToSentry } from '~/ci/utils';
import getPipelineVariablesDefaultRoleSetting from './graphql/queries/get_pipeline_variables_default_role_group_setting.query.graphql';
import updatePipelineVariablesDefaultRoleSetting from './graphql/mutations/update_pipeline_variables_default_role_group_setting.mutation.graphql';

export const DEFAULT_ROLE_DEVELOPER = 'DEVELOPER';
export const DEFAULT_ROLE_MAINTAINER = 'MAINTAINER';
export const DEFAULT_ROLE_NO_ONE = 'NO_ONE_ALLOWED';
export const DEFAULT_ROLE_OWNER = 'OWNER';

export default {
  name: 'PipelineVariablesDefaultRole',
  helpPath: helpPagePath('ci/variables/_index', {
    anchor: 'cicd-variable-precedence',
  }),
  ROLE_OPTIONS: [
    {
      text: __('No one allowed'),
      value: DEFAULT_ROLE_NO_ONE,
      help: s__('CiVariables|Pipeline variables cannot be used.'),
    },
    {
      text: __('Owner'),
      value: DEFAULT_ROLE_OWNER,
    },
    {
      text: __('Maintainer'),
      value: DEFAULT_ROLE_MAINTAINER,
    },
    {
      text: __('Developer'),
      value: DEFAULT_ROLE_DEVELOPER,
    },
  ],
  components: { GlButton, GlFormGroup, GlFormRadio, GlFormRadioGroup, GlLink },
  inject: ['fullPath'],
  data() {
    return {
      isSubmitting: false,
      pipelineVariablesDefaultRole: null,
    };
  },
  apollo: {
    pipelineVariablesDefaultRole: {
      query: getPipelineVariablesDefaultRoleSetting,
      variables() {
        return {
          fullPath: this.fullPath,
        };
      },
      update({ group }) {
        return (
          group?.ciCdSettings?.pipelineVariablesDefaultRole?.toUpperCase() || DEFAULT_ROLE_NO_ONE
        );
      },
      error(err) {
        createAlert({
          message: s__(
            'CiVariables|There was a problem fetching the pipeline variables default role.',
          ),
        });
        reportToSentry(this.$options.name, err);
      },
    },
  },
  methods: {
    async updateDefaultRole() {
      this.isSubmitting = true;
      try {
        const {
          data: {
            namespaceSettingsUpdate: { errors },
          },
        } = await this.$apollo.mutate({
          mutation: updatePipelineVariablesDefaultRoleSetting,
          variables: {
            fullPath: this.fullPath,
            pipelineVariablesDefaultRole: this.pipelineVariablesDefaultRole,
          },
        });

        if (errors.length) {
          createAlert({ message: errors[0].message });
          reportToSentry(this.$options.name, errors[0].message);
        } else {
          this.$toast.show(s__('CiVariables|Pipeline variable access role successfully updated.'));
        }
      } catch (err) {
        createAlert({
          message: s__(
            'CiVariables|There was a problem updating the pipeline variables default role setting.',
          ),
        });
        reportToSentry(this.$options.name, err);
      }
      this.isSubmitting = false;
    },
  },
};
</script>

<template>
  <div class="gl-mb-5">
    <gl-form-group :label="s__('CiVariables|Default role to use pipeline variables')">
      <template #label-description>
        <span>{{
          s__(
            'CiVariables|Select the default minimum role to use in new projects, to run a new pipeline with pipeline variables.',
          )
        }}</span>
        <gl-link :href="$options.helpPath" target="_blank">{{
          s__('CiVariables|What are pipeline variables?')
        }}</gl-link>
      </template>
      <gl-form-radio-group v-model="pipelineVariablesDefaultRole">
        <gl-form-radio v-for="role in $options.ROLE_OPTIONS" :key="role.value" :value="role.value">
          {{ role.text }}
          <template v-if="role.help" #help>{{ role.help }}</template>
        </gl-form-radio>
      </gl-form-radio-group>
      <gl-button
        category="primary"
        variant="confirm"
        class="gl-mt-3"
        :loading="isSubmitting"
        @click="updateDefaultRole"
        >{{ __('Save changes') }}
      </gl-button>
    </gl-form-group>
  </div>
</template>
