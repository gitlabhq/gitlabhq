<script>
import { GlForm, GlFormGroup, GlFormInput, GlFormTextarea, GlButton } from '@gitlab/ui';
import PageHeading from '~/vue_shared/components/page_heading.vue';
import { s__, __ } from '~/locale';
import { MAX_DESCRIPTION_LENGTH } from '~/personal_access_tokens/constants';
import PersonalAccessTokenExpirationDate from './personal_access_token_expiration_date.vue';
import PersonalAccessTokenScopeSelector from './personal_access_token_scope_selector.vue';

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
    GlButton,
  },
  inject: ['accessTokenMaxDate'],
  data() {
    return {
      form: {
        name: '',
        description: '',
        expirationDate: null,
        access: null,
      },
      errors: {
        name: '',
        description: '',
        expirationDate: '',
        access: '',
      },
    };
  },
  computed: {
    hasErrors() {
      return Object.values(this.errors).some((error) => error !== '');
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

      return this.hasErrors;
    },
    createGranularToken() {
      this.validateForm();
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
    cancelButton: __('Cancel'),
    createButton: s__('AccessTokens|Create token'),
  },
};
</script>

<template>
  <div>
    <page-heading :heading="$options.i18n.heading">
      <template #description>
        {{ $options.i18n.description }}
      </template>
    </page-heading>

    <gl-form class="js-quick-submit">
      <section class="gl-w-1/2">
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
      </section>

      <section class="gl-mt-4">
        <gl-button>
          {{ $options.i18n.cancelButton }}
        </gl-button>

        <gl-button variant="confirm" @click="createGranularToken">
          {{ $options.i18n.createButton }}
        </gl-button>
      </section>
    </gl-form>
  </div>
</template>
