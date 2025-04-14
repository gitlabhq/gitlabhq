<script>
import { GlAlert, GlButton, GlFormGroup, GlFormRadio, GlFormRadioGroup, GlLink } from '@gitlab/ui';
import { __, s__ } from '~/locale';
import { reportToSentry } from '~/ci/utils';
import { helpPagePath } from '~/helpers/help_page_helper';
import updatePipelineVariablesMinimumOverrideRoleMutation from './graphql/mutations/update_pipeline_variables_minimum_override_role_project_setting.mutation.graphql';
import getPipelineVariablesMinimumOverrideRoleQuery from './graphql/queries/get_pipeline_variables_minimum_override_role_project_setting.query.graphql';

export const MINIMUM_ROLE_DEVELOPER = 'developer';
export const MINIMUM_ROLE_MAINTAINER = 'maintainer';
export const MINIMUM_ROLE_NO_ONE = 'no_one_allowed';
export const MINIMUM_ROLE_OWNER = 'owner';

export default {
  name: 'PipelineVariablesMinimumOverrideRole',
  helpPath: helpPagePath('ci/variables/_index', {
    anchor: 'restrict-pipeline-variables',
  }),
  ROLE_OPTIONS: [
    {
      text: __('No one allowed'),
      value: MINIMUM_ROLE_NO_ONE,
      help: s__('CiVariables|Pipeline variables cannot be used.'),
    },
    {
      text: __('Owner'),
      value: MINIMUM_ROLE_OWNER,
    },
    {
      text: __('Maintainer'),
      value: MINIMUM_ROLE_MAINTAINER,
    },
    {
      text: __('Developer'),
      value: MINIMUM_ROLE_DEVELOPER,
    },
  ],
  components: {
    GlAlert,
    GlButton,
    GlFormGroup,
    GlFormRadio,
    GlFormRadioGroup,
    GlLink,
  },
  inject: ['fullPath'],
  apollo: {
    minimumOverrideRole: {
      query: getPipelineVariablesMinimumOverrideRoleQuery,
      variables() {
        return {
          fullPath: this.fullPath,
        };
      },
      update({ project }) {
        return (
          project?.ciCdSettings?.pipelineVariablesMinimumOverrideRole || MINIMUM_ROLE_DEVELOPER
        );
      },
      error() {
        this.reportError(__('There was a problem fetching the latest minimum override role.'));
      },
    },
  },
  data() {
    return {
      errorMessage: '',
      isAlertDismissed: false,
      isSubmitting: false,
      minimumOverrideRole: null,
    };
  },
  computed: {
    shouldShowAlert() {
      return this.errorMessage && !this.isAlertDismissed;
    },
  },
  methods: {
    reportError(error) {
      this.errorMessage = error;
      this.isAlertDismissed = false;
      reportToSentry(this.$options.name, error);
    },
    async updateSetting() {
      this.isSubmitting = true;
      try {
        const {
          data: {
            projectCiCdSettingsUpdate: { errors },
          },
        } = await this.$apollo.mutate({
          mutation: updatePipelineVariablesMinimumOverrideRoleMutation,
          variables: {
            fullPath: this.fullPath,
            pipelineVariablesMinimumOverrideRole: this.minimumOverrideRole,
          },
        });

        if (errors.length) {
          this.reportError(errors.join(', '));
        } else {
          this.isAlertDismissed = true;
          this.$toast.show(
            s__('CiVariables|Pipeline variable minimum override role successfully updated.'),
          );
        }
      } catch {
        this.reportError(__('There was a problem updating the minimum override setting.'));
      }
      this.isSubmitting = false;
    },
  },
};
</script>

<template>
  <div class="gl-mb-5">
    <gl-alert
      v-if="shouldShowAlert"
      class="gl-mb-5"
      variant="danger"
      @dismiss="isAlertDismissed = true"
      >{{ errorMessage }}</gl-alert
    >
    <gl-form-group :label="s__('CiVariables|Minimum role to use pipeline variables')">
      <template #label-description>
        <span>{{
          s__(
            'CiVariables|Select the minimum role that is allowed to run a new pipeline with pipeline variables.',
          )
        }}</span>
        <gl-link :href="$options.helpPath" target="_blank">{{
          s__('CiVariables|What are pipeline variables?')
        }}</gl-link>
      </template>
      <gl-form-radio-group v-model="minimumOverrideRole">
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
        :aria-label="__('Save changes')"
        @click="updateSetting"
        >{{ __('Save changes') }}
      </gl-button>
    </gl-form-group>
  </div>
</template>
