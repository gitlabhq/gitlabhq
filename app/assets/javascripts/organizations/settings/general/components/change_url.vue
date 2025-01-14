<script>
import { GlFormFields, GlButton, GlForm, GlCard } from '@gitlab/ui';
import { s__ } from '~/locale';
import { visitUrlWithAlerts, joinPaths } from '~/lib/utils/url_utility';
import { createAlert } from '~/alert';
import OrganizationUrlField from '~/organizations/shared/components/organization_url_field.vue';
import { FORM_FIELD_PATH, FORM_FIELD_PATH_VALIDATORS } from '~/organizations/shared/constants';
import FormErrorsAlert from '~/organizations/shared/components/errors_alert.vue';
import { convertToGraphQLId } from '~/graphql_shared/utils';
import { TYPE_ORGANIZATION } from '~/graphql_shared/constants';
import organizationUpdateMutation from '../graphql/mutations/organization_update.mutation.graphql';

export default {
  name: 'OrganizationSettings',
  components: { OrganizationUrlField, GlFormFields, GlButton, GlForm, GlCard, FormErrorsAlert },
  inject: ['organization'],
  i18n: {
    cardHeaderTitle: s__('Organization|Change organization URL'),
    cardHeaderDescription: s__(
      "Organization|Changing an organization's URL can have unintended side effects.",
    ),
    submitButtonText: s__('Organization|Change organization URL'),
    errorMessage: s__(
      'Organization|An error occurred changing your organization URL. Please try again.',
    ),
    successAlertMessage: s__('Organization|Organization URL successfully changed.'),
  },
  formId: 'change-organization-url-form',
  fields: {
    [FORM_FIELD_PATH]: {
      label: s__('Organization|Organization URL'),
      validators: FORM_FIELD_PATH_VALIDATORS,
      groupAttrs: {
        class: 'gl-w-full',
        labelSrOnly: true,
      },
    },
  },
  data() {
    return {
      formValues: {
        path: this.organization.path,
      },
      loading: false,
      errors: [],
    };
  },
  computed: {
    isSubmitButtonDisabled() {
      return this.formValues.path === this.organization.path;
    },
  },
  methods: {
    async onSubmit() {
      this.errors = [];
      this.loading = true;
      try {
        const {
          data: {
            organizationUpdate: { errors, organization },
          },
        } = await this.$apollo.mutate({
          mutation: organizationUpdateMutation,
          variables: {
            input: {
              id: convertToGraphQLId(TYPE_ORGANIZATION, this.organization.id),
              path: this.formValues.path,
            },
          },
        });

        if (errors.length) {
          this.errors = errors;

          return;
        }

        visitUrlWithAlerts(joinPaths(organization.webUrl, '/settings/general'), [
          {
            id: 'organization-url-successfully-changed',
            message: this.$options.i18n.successAlertMessage,
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
  <div>
    <form-errors-alert v-model="errors" />
    <gl-card class="gl-mt-0">
      <template #header>
        <div class="gl-flex gl-grow">
          <h4 class="gl-m-0 gl-text-base gl-leading-24">{{ $options.i18n.cardHeaderTitle }}</h4>
        </div>
        <p class="gl-m-0 gl-text-sm gl-text-subtle">{{ $options.i18n.cardHeaderDescription }}</p>
      </template>
      <gl-form :id="$options.formId">
        <gl-form-fields
          v-model="formValues"
          :form-id="$options.formId"
          :fields="$options.fields"
          @submit="onSubmit"
        >
          <template #input(path)="{ id, value, validation, input, blur }">
            <organization-url-field
              :id="id"
              :value="value"
              :validation="validation"
              @input="input"
              @blur="blur"
            />
          </template>
        </gl-form-fields>
        <div class="gl-flex gl-gap-3">
          <gl-button
            type="submit"
            variant="danger"
            class="js-no-auto-disable"
            :loading="loading"
            :disabled="isSubmitButtonDisabled"
            >{{ $options.i18n.submitButtonText }}</gl-button
          >
        </div>
      </gl-form>
    </gl-card>
  </div>
</template>
