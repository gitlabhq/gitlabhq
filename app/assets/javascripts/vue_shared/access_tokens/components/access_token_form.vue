<script>
import {
  GlButton,
  GlDatepicker,
  GlForm,
  GlFormCheckboxGroup,
  GlFormCheckbox,
  GlFormFields,
  GlFormTextarea,
  GlLink,
  GlSprintf,
} from '@gitlab/ui';
import { formValidators } from '@gitlab/ui/dist/utils';
import { mapActions, mapState } from 'pinia';
import { helpPagePath } from '~/helpers/help_page_helper';
import { toISODateFormat } from '~/lib/utils/datetime_utility';
import { __, s__ } from '~/locale';

import { useAccessTokens } from '../stores/access_tokens';
import { defaultDate } from '../utils';

export default {
  components: {
    GlButton,
    GlDatepicker,
    GlForm,
    GlFormCheckboxGroup,
    GlFormCheckbox,
    GlFormFields,
    GlFormTextarea,
    GlLink,
    GlSprintf,
    MaxExpirationDateMessage: () =>
      import('ee_component/vue_shared/components/access_tokens/max_expiration_date_message.vue'),
  },
  inject: ['accessTokenMaxDate', 'accessTokenMinDate', 'accessTokenAvailableScopes'],
  props: {
    name: {
      type: String,
      required: false,
      default: '',
    },
    description: {
      type: String,
      required: false,
      default: '',
    },
    scopes: {
      type: Array,
      required: false,
      default: () => [],
    },
  },
  data() {
    const maxDate = this.accessTokenMaxDate ? new Date(this.accessTokenMaxDate) : null;
    if (maxDate) {
      this.$options.fields.expiresAt.validators.push(
        formValidators.required(s__('AccessTokens|Expiration date is required.')),
      );
    }
    const minDate = new Date(this.accessTokenMinDate);
    const expiresAt = defaultDate(maxDate);
    return {
      maxDate,
      minDate,
      values: { expiresAt, name: this.name, description: this.description, scopes: this.scopes },
    };
  },
  computed: {
    ...mapState(useAccessTokens, ['busy']),
  },
  methods: {
    ...mapActions(useAccessTokens, ['createToken', 'setShowCreateForm']),
    clearDatepicker() {
      this.values.expiresAt = null;
    },
    reset() {
      this.setShowCreateForm(false);
    },
    submit() {
      const expiresAt = this.values.expiresAt ? toISODateFormat(this.values.expiresAt) : null;
      this.createToken({ ...this.values, expiresAt });
    },
  },
  helpScopes: helpPagePath('user/profile/personal_access_tokens', {
    anchor: 'personal-access-token-scopes',
  }),
  fields: {
    name: {
      label: s__('AccessTokens|Token name'),
      validators: [formValidators.required(s__('AccessTokens|Token name is required.'))],
      groupAttrs: {
        class: 'gl-form-input-xl',
      },
      inputAttrs: {
        'data-testid': 'access-token-name-field',
      },
    },
    description: {
      label: s__('AccessTokens|Description'),
      groupAttrs: {
        optional: true,
        'optional-text': __('(optional)'),
      },
    },
    expiresAt: {
      label: s__('AccessTokens|Expiration date'),
      validators: [],
    },
    scopes: {
      label: s__('AccessTokens|Select scopes'),
      validators: [
        (value) => (value?.length ? '' : s__('AccessTokens|At least one scope is required.')),
      ],
    },
  },
};
</script>

<template>
  <gl-form
    id="token-create-form"
    class="gl-rounded-base gl-bg-subtle gl-p-5"
    @submit.prevent
    @reset="reset"
  >
    <gl-form-fields
      v-model="values"
      form-id="token-create-form"
      :fields="$options.fields"
      @submit="submit"
    >
      <template #input(description)="{ id, input, value }">
        <gl-form-textarea :id="id" :value="value" @input="input" />
      </template>

      <template #group(expiresAt)-description>
        <max-expiration-date-message :max-date="maxDate" />
      </template>

      <template #input(expiresAt)="{ id, input, validation, value }">
        <gl-datepicker
          show-clear-button
          :max-date="maxDate"
          :min-date="minDate"
          :input-id="id"
          :state="validation.state"
          :value="value"
          :target="null"
          data-testid="expiry-date-field"
          @input="input"
          @clear="clearDatepicker"
        />
      </template>

      <template #group(scopes)-label-description>
        <gl-sprintf
          :message="
            s__(
              'AccessTokens|Scopes set the permission levels granted to the token. %{linkStart}Learn more%{linkEnd}.',
            )
          "
        >
          <template #link="{ content }">
            <gl-link :href="$options.helpScopes" target="_blank">{{ content }}</gl-link>
          </template>
        </gl-sprintf>
      </template>

      <template #input(scopes)="{ id, input, validation, value }">
        <gl-form-checkbox-group :id="id" :state="validation.state" :checked="value" @input="input">
          <gl-form-checkbox
            v-for="scope in accessTokenAvailableScopes"
            :key="scope.value"
            :value="scope.value"
            :state="validation.state"
            :data-testid="`${scope.value}-checkbox`"
          >
            {{ scope.value }}
            <template #help>{{ scope.text }}</template>
          </gl-form-checkbox>
        </gl-form-checkbox-group>
      </template>
    </gl-form-fields>

    <div class="gl-flex gl-gap-3">
      <gl-button
        variant="confirm"
        type="submit"
        class="js-no-auto-disable"
        :loading="busy"
        data-testid="create-token-button"
      >
        {{ s__('AccessTokens|Create token') }}
      </gl-button>
      <gl-button variant="default" type="reset">
        {{ __('Cancel') }}
      </gl-button>
    </div>
  </gl-form>
</template>
