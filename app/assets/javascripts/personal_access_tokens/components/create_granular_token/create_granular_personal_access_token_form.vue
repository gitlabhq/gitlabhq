<script>
import { GlForm, GlFormGroup, GlFormInput, GlFormTextarea, GlButton } from '@gitlab/ui';
import PageHeading from '~/vue_shared/components/page_heading.vue';
import { scrollTo } from '~/lib/utils/scroll_utils';
import { s__, __ } from '~/locale';
import { createAlert } from '~/alert';
import createGranularPersonalAccessTokenMutation from '~/personal_access_tokens/graphql/create_granular_personal_access_token.mutation.graphql';
import {
  ACCESS_SELECTED_MEMBERSHIPS_ENUM,
  MAX_DESCRIPTION_LENGTH,
} from '~/personal_access_tokens/constants';
import PersonalAccessTokenExpirationDate from './personal_access_token_expiration_date.vue';
import PersonalAccessTokenScopeSelector from './personal_access_token_scope_selector.vue';
import PersonalAccessTokenNamespaceSelector from './personal_access_token_namespace_selector.vue';
import PersonalAccessTokenPermissionsSelector from './personal_access_token_permissions_selector.vue';
import CreatedPersonalAccessToken from './created_personal_access_token.vue';

export default {
  name: 'CreateGranularPersonalAccessTokenForm',
  components: {
    PageHeading,
    GlForm,
    GlFormGroup,
    GlFormInput,
    GlFormTextarea,
    PersonalAccessTokenExpirationDate,
    PersonalAccessTokenScopeSelector,
    PersonalAccessTokenNamespaceSelector,
    PersonalAccessTokenPermissionsSelector,
    GlButton,
    CreatedPersonalAccessToken,
  },
  inject: ['accessTokenMaxDate', 'accessTokenTableUrl'],
  data() {
    return {
      form: {
        name: '',
        description: '',
        expirationDate: null,
        access: null,
        namespaceIds: [],
        permissions: [],
      },
      errors: {
        name: '',
        description: '',
        expirationDate: '',
        access: '',
        namespaceIds: '',
        permissions: '',
      },
      isSubmitting: false,
      createdToken: null,
    };
  },
  computed: {
    hasErrors() {
      return Object.values(this.errors).some((error) => error !== '');
    },
    renderNamespaceSelector() {
      return this.form.access === ACCESS_SELECTED_MEMBERSHIPS_ENUM;
    },
  },
  methods: {
    validateForm() {
      // reset the validation
      this.errors = {
        name: '',
        description: '',
        expirationDate: '',
        access: '',
        namespaceIds: '',
        permissions: '',
      };

      if (!this.form.name) {
        this.errors.name = this.$options.i18n.nameError;
      }

      if (!this.form.description) {
        this.errors.description = this.$options.i18n.descriptionError;
      } else if (this.form.description.length > MAX_DESCRIPTION_LENGTH) {
        this.errors.description = this.$options.i18n.descriptionLengthError;
      }

      if (this.accessTokenMaxDate && !this.form.expirationDate) {
        this.errors.expirationDate = this.$options.i18n.expirationDateError;
      }

      if (!this.form.access) {
        this.errors.access = this.$options.i18n.scopeError;
      }

      if (this.renderNamespaceSelector && !this.form.namespaceIds.length) {
        this.errors.namespaceIds = this.$options.i18n.namespaceError;
      }

      if (!this.form.permissions.length) {
        this.errors.permissions = this.$options.i18n.permissionsError;
      }

      return this.hasErrors;
    },
    createGranularToken() {
      if (this.validateForm()) {
        return;
      }

      this.isSubmitting = true;

      this.$apollo
        .mutate({
          mutation: createGranularPersonalAccessTokenMutation,
          variables: {
            input: {
              name: this.form.name,
              description: this.form.description,
              expiresAt: this.form.expirationDate,
              granularScopes: [
                {
                  access: this.form.access,
                  resourceIds: this.form.namespaceIds,
                  permissions: this.form.permissions,
                },
              ],
            },
          },
          update: (_, { data: { personalAccessTokenCreate } }) => {
            const { token, errors } = personalAccessTokenCreate;

            if (errors?.length) {
              throw Error(errors.join(','));
            }

            this.createdToken = token;
          },
        })
        .catch((error) => {
          scrollTo({ top: 0, behavior: 'smooth' }, this.$el);

          createAlert({
            message: this.$options.i18n.createError,
            captureError: true,
            error,
          });
        })
        .finally(() => {
          this.isSubmitting = false;
        });
    },
  },
  i18n: {
    heading: s__('AccessTokens|Generate fine-grained token'),
    description: s__(
      'AccessTokens|Fine-grained personal access tokens give you granular control over the specific resources and actions available to the token.',
    ),
    nameLabel: s__('AccessTokens|Name'),
    nameError: s__('AccessTokens|Token name is required.'),
    descriptionLabel: s__('AccessTokens|Description'),
    descriptionError: s__('AccessTokens|Token description is required.'),
    descriptionLengthError: s__(
      'AccessTokens|Description is too long (maximum is 255 characters).',
    ),
    expirationDateError: s__('AccessTokens|Expiration date is required.'),
    scopeError: s__('AccessTokens|At least one scope is required.'),
    namespaceError: s__('AccessTokens|At least one group or project is required.'),
    permissionsError: s__('AccessTokens|At least one permission is required.'),
    cancelButton: __('Cancel'),
    createButton: s__('AccessTokens|Generate token'),
    createError: s__('AccessTokens|Token generation unsuccessful. Please try again.'),
  },
};
</script>

<template>
  <div>
    <created-personal-access-token v-if="createdToken" v-model="createdToken" />

    <div v-else>
      <page-heading :heading="$options.i18n.heading">
        <template #description>
          {{ $options.i18n.description }}
        </template>
      </page-heading>

      <gl-form class="js-quick-submit">
        <section class="gl-w-full lg:gl-w-1/2">
          <gl-form-group
            :label="$options.i18n.nameLabel"
            label-for="token-name"
            :invalid-feedback="errors.name"
            :state="!errors.name"
          >
            <gl-form-input id="token-name" v-model.trim="form.name" :state="!errors.name" />
          </gl-form-group>

          <gl-form-group
            :label="$options.i18n.descriptionLabel"
            label-for="token-description"
            :invalid-feedback="errors.description"
            :state="!errors.description"
          >
            <gl-form-textarea
              id="token-description"
              v-model.trim="form.description"
              :state="!errors.description"
            />
          </gl-form-group>

          <personal-access-token-expiration-date
            v-model="form.expirationDate"
            :error="errors.expirationDate"
          />

          <personal-access-token-scope-selector v-model="form.access" :error="errors.access" />

          <personal-access-token-namespace-selector
            v-if="renderNamespaceSelector"
            v-model="form.namespaceIds"
            :error="errors.namespaceIds"
          />
        </section>

        <section>
          <personal-access-token-permissions-selector
            v-model="form.permissions"
            :error="errors.permissions"
          />
        </section>

        <section class="gl-mt-6">
          <gl-button :href="accessTokenTableUrl">
            {{ $options.i18n.cancelButton }}
          </gl-button>

          <gl-button variant="confirm" :loading="isSubmitting" @click="createGranularToken">
            {{ $options.i18n.createButton }}
          </gl-button>
        </section>
      </gl-form>
    </div>
  </div>
</template>
