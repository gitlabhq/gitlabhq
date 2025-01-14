<script>
import { s__, __ } from '~/locale';
import { createAlert } from '~/alert';
import { visitUrlWithAlerts } from '~/lib/utils/url_utility';
import NewEditForm from '~/organizations/shared/components/new_edit_form.vue';
import {
  FORM_FIELD_NAME,
  FORM_FIELD_ID,
  FORM_FIELD_DESCRIPTION,
  FORM_FIELD_AVATAR,
} from '~/organizations/shared/constants';
import FormErrorsAlert from '~/organizations/shared/components/errors_alert.vue';
import SettingsBlock from '~/vue_shared/components/settings/settings_block.vue';
import { convertToGraphQLId } from '~/graphql_shared/utils';
import { TYPE_ORGANIZATION } from '~/graphql_shared/constants';
import organizationUpdateMutation from '../graphql/mutations/organization_update.mutation.graphql';

export default {
  name: 'OrganizationSettings',
  components: { NewEditForm, SettingsBlock, FormErrorsAlert },
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
  fieldsToRender: [FORM_FIELD_NAME, FORM_FIELD_ID, FORM_FIELD_DESCRIPTION, FORM_FIELD_AVATAR],
  data() {
    return {
      loading: false,
      errors: [],
    };
  },
  methods: {
    avatarInput(formValues) {
      // Organization has an avatar and it is been explicitly removed.
      if (this.organization.avatar && formValues.avatar === null) {
        return { avatar: null };
      }

      // Avatar has been set or changed.
      if (formValues.avatar instanceof File) {
        return { avatar: formValues.avatar };
      }

      // Avatar has not been changed at all, do not include the `avatar` key in input.
      return {};
    },
    async onSubmit(formValues) {
      this.errors = [];
      this.loading = true;

      try {
        const {
          data: {
            organizationUpdate: { errors },
          },
        } = await this.$apollo.mutate({
          mutation: organizationUpdateMutation,
          variables: {
            input: {
              id: convertToGraphQLId(TYPE_ORGANIZATION, this.organization.id),
              name: formValues.name,
              description: formValues.description,
              ...this.avatarInput(formValues),
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

        visitUrlWithAlerts(window.location.href, [
          {
            id: 'organization-successfully-updated',
            message: this.$options.i18n.successMessage,
            variant: 'info',
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
  <settings-block
    id="organization-settings"
    :title="$options.i18n.settingsBlock.title"
    default-expanded
  >
    <template #description>{{ $options.i18n.settingsBlock.description }}</template>
    <template #default>
      <form-errors-alert v-model="errors" :scroll-on-error="true" />
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
