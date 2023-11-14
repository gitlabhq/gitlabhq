<script>
import { s__, __ } from '~/locale';
import { createAlert, VARIANT_INFO } from '~/alert';
import NewEditForm from '~/organizations/shared/components/new_edit_form.vue';
import { FORM_FIELD_NAME, FORM_FIELD_ID } from '~/organizations/shared/constants';
import SettingsBlock from '~/vue_shared/components/settings/settings_block.vue';
import updateOrganizationMutation from '../graphql/mutations/update_organization.mutation.graphql';

export default {
  name: 'OrganizationSettings',
  components: { NewEditForm, SettingsBlock },
  inject: ['organization'],
  i18n: {
    submitButtonText: __('Save changes'),
    settingsBlock: {
      title: s__('Organization|Organization settings'),
      description: s__('Organization|Update your organization name, description, and avatar.'),
    },
    errorMessage: s__(
      'Organization|An error occurred updating your organization. Please try again.',
    ),
    successMessage: s__('Organization|Organization was successfully updated.'),
  },
  fieldsToRender: [FORM_FIELD_NAME, FORM_FIELD_ID],
  data() {
    return {
      loading: false,
    };
  },
  methods: {
    async onSubmit(formValues) {
      this.loading = true;
      try {
        const {
          data: {
            updateOrganization: { errors },
          },
        } = await this.$apollo.mutate({
          mutation: updateOrganizationMutation,
          variables: {
            id: this.organization.id,
            name: formValues.name,
          },
        });

        if (errors.length) {
          // TODO: handle errors when using real API after https://gitlab.com/gitlab-org/gitlab/-/issues/419608 is complete.
          return;
        }

        createAlert({ message: this.$options.i18n.successMessage, variant: VARIANT_INFO });
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
  <settings-block default-expanded slide-animated>
    <template #title>{{ $options.i18n.settingsBlock.title }}</template>
    <template #description>{{ $options.i18n.settingsBlock.description }}</template>
    <template #default>
      <new-edit-form
        :loading="loading"
        :initial-form-values="organization"
        :fields-to-render="$options.fieldsToRender"
        :submit-button-text="$options.i18n.submitButtonText"
        :show-cancel-button="false"
        @submit="onSubmit"
      />
    </template>
  </settings-block>
</template>
