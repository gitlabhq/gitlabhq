<script>
import { GlSprintf, GlLink } from '@gitlab/ui';
import { s__ } from '~/locale';
import { visitUrlWithAlerts } from '~/lib/utils/url_utility';
import { createAlert } from '~/alert';
import { helpPagePath } from '~/helpers/help_page_helper';
import FormErrorsAlert from '~/organizations/shared/components/errors_alert.vue';
import organizationCreateMutation from '../graphql/mutations/organization_create.mutation.graphql';
import NewEditForm from '../../shared/components/new_edit_form.vue';

export default {
  name: 'OrganizationNewApp',
  components: { NewEditForm, GlSprintf, GlLink, FormErrorsAlert },
  i18n: {
    pageTitle: s__('Organization|New organization'),
    pageDescription: s__(
      'Organization|%{linkStart}Organizations%{linkEnd} are a top-level container to hold your groups and projects.',
    ),
    errorMessage: s__('Organization|An error occurred creating an organization. Please try again.'),
    successAlertTitle: s__('Organization|Organization successfully created.'),
    successAlertMessage: s__('Organization|You can now start using your new organization.'),
  },
  data() {
    return {
      loading: false,
      errors: [],
    };
  },
  computed: {
    organizationsHelpPagePath() {
      return helpPagePath('user/organization/_index');
    },
  },
  methods: {
    async onSubmit(formValues) {
      this.loading = true;
      try {
        const {
          data: {
            organizationCreate: { organization, errors },
          },
        } = await this.$apollo.mutate({
          mutation: organizationCreateMutation,
          variables: {
            input: {
              name: formValues.name,
              path: formValues.path,
              description: formValues.description,
              avatar: formValues.avatar,
            },
          },
          context: {
            hasUpload: formValues.avatar instanceof File,
          },
        });

        if (errors.length) {
          this.errors = errors;

          return;
        }

        visitUrlWithAlerts(organization.webUrl, [
          {
            id: 'organization-successfully-created',
            title: this.$options.i18n.successAlertTitle,
            message: this.$options.i18n.successAlertMessage,
            variant: 'success',
          },
        ]);
      } catch (error) {
        createAlert({ message: this.$options.i18n.errorMessage, error, captureError: true });
      } finally {
        this.loading = false;
      }
    },
  },
};
</script>

<template>
  <div class="gl-py-6">
    <h1 class="gl-mt-0 gl-text-size-h-display">{{ $options.i18n.pageTitle }}</h1>
    <p>
      <gl-sprintf :message="$options.i18n.pageDescription">
        <template #link="{ content }"
          ><gl-link :href="organizationsHelpPagePath">{{ content }}</gl-link></template
        >
      </gl-sprintf>
    </p>
    <form-errors-alert v-model="errors" :scroll-on-error="true" />
    <new-edit-form :loading="loading" @submit="onSubmit" />
  </div>
</template>
