<script>
import { GlSprintf } from '@gitlab/ui';
import { __, s__ } from '~/locale';
import NewEditForm from '~/projects/components/new_edit_form.vue';
import { FORM_FIELD_NAME, FORM_FIELD_DESCRIPTION } from '~/projects/components/constants';
import { updateProject } from '~/rest_api';
import { visitUrlWithAlerts } from '~/lib/utils/url_utility';
import { createAlert } from '~/alert';

export default {
  name: 'OrganizationProjectsEditApp',
  components: { GlSprintf, NewEditForm },
  i18n: {
    pageTitle: __('Edit project: %{project_name}'),
    errorMessage: s__('ProjectsEdit|An error occurred updating this project. Please try again.'),
    successMessage: s__('ProjectsEdit|Project was successfully updated.'),
  },
  inject: ['projectsOrganizationPath', 'previewMarkdownPath', 'project'],
  data() {
    return {
      loading: false,
      serverValidations: {},
    };
  },
  methods: {
    async onSubmit({ [FORM_FIELD_NAME]: name, [FORM_FIELD_DESCRIPTION]: description }) {
      this.loading = true;

      try {
        await updateProject(this.project.id, {
          name,
          description,
        });

        visitUrlWithAlerts(window.location.href, [
          {
            id: 'organization-project-successfully-updated',
            message: this.$options.i18n.successMessage,
            variant: 'info',
          },
        ]);
      } catch (error) {
        this.loading = false;

        const fieldsToValidate = {
          [FORM_FIELD_NAME]: s__('ProjectsNew|Project name'),
          [FORM_FIELD_DESCRIPTION]: s__('ProjectsNewEdit|Project description'),
        };
        this.serverValidations = Object.entries(error?.response?.data?.message || {}).reduce(
          (accumulator, [fieldName, errorMessages]) => {
            const fieldLabel = fieldsToValidate[fieldName];

            if (!fieldLabel || !errorMessages.length) {
              return accumulator;
            }

            return {
              ...accumulator,
              [fieldName]: `${fieldLabel} ${errorMessages[0]}`,
            };
          },
          {},
        );

        if (!Object.keys(this.serverValidations).length) {
          createAlert({ message: this.$options.i18n.errorMessage, error, captureError: true });
        }
      }
    },
    onInputField({ name }) {
      const copy = { ...this.serverValidations };
      delete copy[name];
      this.serverValidations = copy;
    },
  },
};
</script>

<template>
  <div class="gl-py-6">
    <h1 class="gl-mt-0 gl-text-size-h-display">
      <gl-sprintf :message="$options.i18n.pageTitle">
        <template #project_name>{{ project.fullName }}</template>
      </gl-sprintf>
    </h1>
    <new-edit-form
      :loading="loading"
      :initial-form-values="project"
      :server-validations="serverValidations"
      :preview-markdown-path="previewMarkdownPath"
      :cancel-button-href="projectsOrganizationPath"
      @submit="onSubmit"
      @input-field="onInputField"
    />
  </div>
</template>
