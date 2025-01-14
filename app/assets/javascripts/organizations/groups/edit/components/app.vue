<script>
import { GlSprintf } from '@gitlab/ui';
import NewEditForm from '~/groups/components/new_edit_form.vue';
import { FORM_FIELD_NAME, FORM_FIELD_PATH, FORM_FIELD_VISIBILITY_LEVEL } from '~/groups/constants';
import { __, s__ } from '~/locale';
import { VISIBILITY_LEVELS_INTEGER_TO_STRING } from '~/visibility_level/constants';
import { visitUrlWithAlerts } from '~/lib/utils/url_utility';
import { createAlert } from '~/alert';
import FormErrorsAlert from '~/organizations/shared/components/errors_alert.vue';
import groupUpdateMutation from '../graphql/mutations/group_update.mutation.graphql';

export default {
  name: 'OrganizationGroupsEditApp',
  components: { GlSprintf, FormErrorsAlert, NewEditForm },
  i18n: {
    pageTitle: __('Edit group: %{group_name}'),
    submitButtonText: __('Save changes'),
    errorMessage: s__('Groups|An error occurred updating this group. Please try again.'),
    successMessage: __('Group was successfully updated.'),
  },
  inject: [
    'group',
    'basePath',
    'groupsAndProjectsOrganizationPath',
    'groupsOrganizationPath',
    'availableVisibilityLevels',
    'restrictedVisibilityLevels',
    'defaultVisibilityLevel',
    'pathMaxlength',
    'pathPattern',
  ],
  data() {
    return {
      loading: false,
      errors: [],
    };
  },
  methods: {
    async onSubmit({
      [FORM_FIELD_NAME]: name,
      [FORM_FIELD_PATH]: path,
      [FORM_FIELD_VISIBILITY_LEVEL]: visibility,
    }) {
      try {
        this.loading = true;

        const {
          data: {
            groupUpdate: { group, errors },
          },
        } = await this.$apollo.mutate({
          mutation: groupUpdateMutation,
          variables: {
            input: {
              fullPath: this.group.fullPath,
              name,
              path,
              visibility: VISIBILITY_LEVELS_INTEGER_TO_STRING[visibility],
            },
          },
        });

        if (errors.length) {
          this.errors = errors;
          this.loading = false;

          return;
        }

        visitUrlWithAlerts(group.organizationEditPath, [
          {
            id: 'organization-group-successfully-updated',
            message: this.$options.i18n.successMessage,
            variant: 'info',
          },
        ]);
      } catch (error) {
        this.loading = false;
        createAlert({ message: this.$options.i18n.errorMessage, error, captureError: true });
      }
    },
  },
};
</script>

<template>
  <div class="gl-py-6">
    <h1 class="gl-mt-0 gl-text-size-h-display">
      <gl-sprintf :message="$options.i18n.pageTitle">
        <template #group_name>{{ group.fullName }}</template>
      </gl-sprintf>
    </h1>
    <form-errors-alert v-model="errors" :scroll-on-error="true" />
    <new-edit-form
      :loading="loading"
      :base-path="basePath"
      :path-maxlength="pathMaxlength"
      :path-pattern="pathPattern"
      :submit-button-text="$options.i18n.submitButtonText"
      :cancel-path="groupsAndProjectsOrganizationPath"
      :available-visibility-levels="availableVisibilityLevels"
      :restricted-visibility-levels="restrictedVisibilityLevels"
      :initial-form-values="group"
      @submit="onSubmit"
    />
  </div>
</template>
